--Note: Wait for answer from question APPLINK-13276 to update expected result for test cases that related to info parameter in response. 
	--Updated for APPLINK-13276
--Current defects: 
	--APPLINK-9734: ResetGlobalProperties doesn't reset HELPPROMPT and VRHELPITEMS to default values
	--APPLINK-13235: ResetGlobalProperties: send TTS.SetGlobalProperties with a redundant comma at the end of text value in timeoutPrompt parameter
		--Because of APPLINK-13235, most of all test cases use timeoutPrompt text is the same as actual result to avoid this defect. When this defect is fixed, should search and replace this case to correct one.
	-- Some test cases are commented (such as test cases related to invalid_JSON and Fake parameter) to avoid current error of ATF. Uncomment these test cases, remove other test cases and run again to check for these cases.
	
--Update value for strAppFolder to real folder on test PC.
---------------------------------------------------------------------------------------------
local commonSteps   = require('user_modules/shared_testcases/commonSteps')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

  
function DeleteLog_app_info_dat_policy()
    commonSteps:CheckSDLPath()
    local SDLStoragePath = config.pathToSDL .. "storage/"

    --Delete app_info.dat and log files and storage
    if commonSteps:file_exists(config.pathToSDL .. "app_info.dat") == true then
      os.remove(config.pathToSDL .. "app_info.dat")
    end

    if commonSteps:file_exists(config.pathToSDL .. "SmartDeviceLinkCore.log") == true then
      os.remove(config.pathToSDL .. "SmartDeviceLinkCore.log")
    end

    if commonSteps:file_exists(SDLStoragePath .. "policy.sqlite") == true then
      os.remove(SDLStoragePath .. "policy.sqlite")
    end

    if commonSteps:file_exists(config.pathToSDL .. "policy.sqlite") == true then
      os.remove(config.pathToSDL .. "policy.sqlite")
    end
print("path = " .."rm -r " ..config.pathToSDL .. "storage")
    os.execute("rm -r " ..config.pathToSDL .. "storage")
end

DeleteLog_app_info_dat_policy()

function UpdatePolicy()
    commonPreconditions:BackupFile("sdl_preloaded_pt.json")
    local src_preloaded_json = config.pathToSDL .."sdl_preloaded_pt.json"
    local dest               = "files/SetGlobalProperties_DISALLOWED.json"
    
    local filecopy = "cp " .. dest .."  " .. src_preloaded_json

    os.execute(filecopy)
end

UpdatePolicy()

local icon_to_check
local title_to_check = "MENU"
local SDLini        = config.pathToSDL .. tostring("smartDeviceLink.ini")
-----------------------------------------------------------------------------------------
-- This function check in INI file path of menu_icon and menuTitle
-- parameters: NO
-----------------------------------------------------------------------------------------
local function CheckINI()
	
	f = assert(io.open(SDLini, "r"))

	local fileContentUpdated = false
	local fileContent = f:read("*all")
	local menuIconContent = fileContent:match('menuIcon%s*=%s*[a-zA-Z%/0-9%_.]+[^\n]')
	local default_path
	 	
	-- Check menuIcon
	if not menuIconContent then
		--APPLINK-29383 => APPLINK-13145, comment from Stefan
		print ("\27[31m ERROR: menuIcon is not found in smartDeviceLink.ini \27[0m " )
	else	
		--for split_menuicon in string.gmatch(menuIconContent,"[^=]*") do
		for split_menuicon in string.gmatch(menuIconContent,"[^%s]+") do
			if( (split_menuicon ~= nil) and (#split_menuicon > 1) ) then
				default_path = split_menuicon
			end
		end
		icon_to_check = default_path
	end

	-- Check menuTitle
	local menuTitleContent = fileContent:match('menuTitle%s*=%s*[a-zA-Z%/0-9%_.]+[^\n]')
	local default_title
	 	
	if not menuTitleContent then
		--APPLINK-29383 => APPLINK-13145, comment from Stefan
		print ("\27[31m ERROR: menuTitle is not found in smartDeviceLink.ini \27[0m " )
	else	
		--for split_menuicon in string.gmatch(menuTitleContent,"[^=]*") do
		for split_menuicon in string.gmatch(menuTitleContent,"[^%s]+") do
			if( (split_menuicon ~= nil) and (#split_menuicon > 1) ) then
				default_title = split_menuicon
			end
		end
	end

	if (default_title ~= "MENU") then
		print ("\27[31m ERROR: menuTitle is not equal to MENU in smartDeviceLink.ini \27[0m " )
		return false
	end

	f:close()
end

CheckINI()

Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local mobile  = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')

config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
--ToDo: shall be removed when APPLINK-16610 is fixed
config.defaultProtocolVersion = 2
config.SDLStoragePath = config.pathToSDL .. "storage/"

---------------------------------------------------------------------------------------------
-----------------------------Required Shared Libraries---------------------------------------
---------------------------------------------------------------------------------------------
require('user_modules/AppTypes')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
APIName = "ResetGlobalProperties" -- use for above required scripts.
strMaxLengthFileName255 = string.rep("a", 251)  .. ".png" -- set max length file name


local iTimeout = 5000
local strAppFolder = config.SDLStoragePath .. config.application1.registerAppInterfaceParams.fullAppID .. "_" .. config.deviceMAC .. "/"

local str1000Chars = 
	"1".. --1
	"0123456789".. --10
	"ABCDEFGHIJKLMNOPQRSTUVWXYZ".. --26
	"abcdefghijklmnopqrstuvwxyz".. --26 + 38 +  899
	"a b c                                 ".. 					"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
	
local str1000Chars2 = 
	"2".. --1
	"0123456789".. --10
	"ABCDEFGHIJKLMNOPQRSTUVWXYZ".. --26
	"abcdefghijklmnopqrstuvwxyz".. --26 + 38 +  899
	"a b c                                 ".. 					"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"


local textPromtValue = {"Please speak one of the following commands," ,"Please say a command,"}
---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------
	--Begin Precondition.1
	--Description: Register app with VRSynonym
	
		function Test:Precondition_SecondSession()
			--mobile side: start new session
			self.mobileSession2 = mobile_session.MobileSession(
			self,
			self.mobileConnection)
		end
			
		function Test:RegisterAppInterface_WithConditionalParams()
			self.mobileSession2:StartService(7)
			:Do(function()
				--mobile side: RegisterAppInterface request 
				local CorIdRAI = self.mobileSession2:SendRPC("RegisterAppInterface",
															{
																 
																syncMsgVersion = 
																{ 
																	majorVersion = 2,
																	minorVersion = 2,
																}, 
																appName = "Test Application2",
																ttsName = 
																{	 
																	{ 
																		text ="SyncProxyTester",
																		type ="TEXT",
																	}, 
																}, 
																ngnMediaScreenAppName ="SPT",
																vrSynonyms = 
																{ 
																	"VRSyncProxyTester1",
																	"VRSyncProxyTester2"
																}, 
																isMediaApplication = true,
																languageDesired ="EN-US",
																hmiDisplayLanguageDesired ="EN-US",
																appHMIType = 
																{ 
																	"NAVIGATION",
																}, 
																appID ="3",
																deviceInfo = 
																{
																	hardware = "hardware",
																	firmwareRev = "firmwareRev",
																	os = "os",
																	osVersion = "osVersion",
																	carrier = "carrier",
																	maxNumberRFCOMMPorts = 5
																}
															
															})
				

				--hmi side: expected  BasicCommunication.OnAppRegistered
					EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
								{
									application = 
									{
										appName = "Test Application2",
										ngnMediaScreenAppName ="SPT",
										--[=[TODO: update after resolving APPLINK-16052
										deviceInfo = 
										{
											name = "127.0.0.1",
											id = config.deviceMAC,
											transportType = "WIFI",
											isSDLAllowed = true
										},]=]
										policyAppID = "3",
										hmiDisplayLanguageDesired ="EN-US",
										isMediaApplication = true,
										appType = 
										{ 
											"NAVIGATION"
										},
									},
									ttsName = 
									{ 
										 
										{ 
											text ="SyncProxyTester",
											type ="TEXT",
										}
									},
									vrSynonyms = 
									{ 
										"VRSyncProxyTester1",
										"VRSyncProxyTester2"
									}
								})
				:Do(function(_,data)
					self.appID2 = data.params.application.appID
				end)
				--mobile side: RegisterAppInterface response 
				self.mobileSession2:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})
				:Timeout(2000)

				self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
			end)
		end
				
	--End Precondition.1

	-----------------------------------------------------------------------------------------

	--1. Activate application
	commonSteps:ActivationApp()
	
	--2. PutFiles	
	commonSteps:PutFile("FutFile_MinLength", "a")

---------------------------------------------------------------------------------------------
-----------------------------------------I TEST BLOCK----------------------------------------
--CommonRequestCheck: Check of mandatory/conditional request's parameters (mobile protocol)--
---------------------------------------------------------------------------------------------

	--Begin Test suit CommonRequestCheck
	--Description:
		-- request with all parameters
		-- request with only mandatory parameters
		-- request with all combinations of conditional-mandatory parameters (if exist)
		-- request with one by one conditional parameters (each case - one conditional parameter)
		-- request with missing mandatory parameters one by one (each case - missing one mandatory parameter)
		-- request with all parameters are missing
		-- request with fake parameters (fake - not from protocol, from another request)
		-- request is sent with invalid JSON structure
		-- different conditions of correlationID parameter (invalid, several the same etc.)

		--Begin Test case CommonRequestCheck.1
		--Description: check request with all parameters
				
				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-18

				--Verification criteria: ResetGlobalProperties request resets the requested GlobalProperty values to default ones.
				function Test:ResetGlobalProperties_PositiveCase()
				
					--mobile side: sending ResetGlobalProperties request
					local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
					{
						properties = 
						{
							"VRHELPTITLE",
							"MENUNAME",
							"MENUICON",
							"KEYBOARDPROPERTIES",
							"VRHELPITEMS",
							"HELPPROMPT",
							"TIMEOUTPROMPT"
						}
					})
					--hmi side: expect TTS.SetGlobalProperties request
					EXPECT_HMICALL("TTS.SetGlobalProperties",
					{
						--[=[ TODO: update after resolving APPLINK-9734
						helpPrompt = 
						{
							{
								type = "TEXT",
								text = textPromtValue[1]
							},
							{
								type = "TEXT",
								text = textPromtValue[2]
							}
						},]=]
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
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending TTS.SetGlobalProperties response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)
				

					--hmi side: expect UI.SetGlobalProperties request
					EXPECT_HMICALL("UI.SetGlobalProperties",
					{
						menuTitle = title_to_check,
						menuIcon = {
										imageType = "DYNAMIC",
										value = icon_to_check
									},
						vrHelpTitle = "Test Application",
						keyboardProperties = 
						{
							keyboardLayout = "QWERTY",
							autoCompleteText = "",
							language = "EN-US"
						},
						vrHelp = nil
					})
					
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)				

					--mobile side: expect SetGlobalProperties response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
					:Timeout(iTimeout)
					
					EXPECT_NOTIFICATION("OnHashChange")
					:Timeout(iTimeout)
				end

		--End Test case CommonRequestCheck.1
		
		-----------------------------------------------------------------------------------------
		
		--Skipped CommonRequestCheck.2-5: There next checks are not applicable:
			-- request with only mandatory parameters
			-- request with all combinations of conditional-mandatory parameters (if exist)
			-- request with one by one conditional parameters (each case - one conditional parameter)
			-- request with missing mandatory parameters one by one (each case - missing one mandatory parameter)

		-----------------------------------------------------------------------------------------

		
		--Begin Test case CommonRequestCheck.6
		--Description: check request with all parameters are missing
				
				--Requirement id in JAMA/or Jira ID: 
					-- SDLAQ-CRS-18
					-- SDLAQ-CRS-395

				--Verification criteria: SDL responses invalid data
 
				function Test:ResetGlobalProperties_MissingAllParams()
				
					--mobile side: sending ReResetGlobalProperties request
					local cid = self.mobileSession:SendRPC("SetGlobalProperties",
					{

					})
				

					--mobile side: expect SetGlobalProperties response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
					:Timeout(iTimeout)
					
					EXPECT_NOTIFICATION("OnHashChange")
					:Timeout(12000)
					:Times(0)				
				end

		--End Test case CommonRequestCheck.6
		
		-----------------------------------------------------------------------------------------
		
		--Begin Test case CommonRequestCheck.7
		--Description: Check request with fake parameters
			
			--Requirement id in JAMA/or Jira ID: APPLINK-4518

			--Verification criteria: According to xml tests by Ford team all fake params should be ignored by SDL
				
			--Begin Test case CommonRequestCheck.7.1
			--Description: Fake parameter

				function Test:ResetGlobalProperties_FakeParameters()
				
					--mobile side: sending ResetGlobalProperties request
					local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
					{
						fakeParam = "fakeparameters",
						properties = 
						{
							"VRHELPTITLE",
							"MENUNAME",
							"MENUICON",
							"KEYBOARDPROPERTIES",
							"VRHELPITEMS",
							"HELPPROMPT",
							"TIMEOUTPROMPT"
						}
					})
					--hmi side: expect TTS.SetGlobalProperties request
					EXPECT_HMICALL("TTS.SetGlobalProperties",
					{
						--[=[ TODO: update after resolving APPLINK-9734
						helpPrompt = 
						{
							{
								type = "TEXT",
								text = textPromtValue[1]
							},
							{
								type = "TEXT",
								text = textPromtValue[2]
							}
						},]=]
						timeoutPrompt = 
						{
							{
								type = "TEXT",
								text = "Please speak one of the following commands,"
							},
							{
								type = "TEXT",
								text = "Please say a command,"
							}
						}
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending TTS.SetGlobalProperties response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)
					:ValidIf(function(_,data)
						if data.params.fakeParam then 
							print ("\27[35m Request came with fake parameter \27[0m")
							return false
						else
							return true
						end
					end)
				

					--hmi side: expect UI.SetGlobalProperties request
					EXPECT_HMICALL("UI.SetGlobalProperties",
					{
						menuTitle = title_to_check,
						menuIcon = {
										imageType = "DYNAMIC",
										value = icon_to_check
									},
						vrHelpTitle = "Test Application",
						keyboardProperties = 
						{
							keyboardLayout = "QWERTY",
							autoCompleteText = "",
							language = "EN-US"
						},
						vrHelp = nil
					})
					
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)
					:ValidIf(function(_,data)
						if data.params.fakeParam then 
							print ("\27[35m Request came with fake parameter \27[0m")
							return false
						else
							return true
						end
					end)				

					--mobile side: expect SetGlobalProperties response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
					:Timeout(iTimeout)
					
					EXPECT_NOTIFICATION("OnHashChange")
					:Timeout(iTimeout)
				end

			--End Test case CommonRequestCheck.7.1
			
			-----------------------------------------------------------------------------------------
						
			--Begin Test case CommonRequestCheck.7.2
			--Description: Parameters from another request

				function Test:ResetGlobalProperties_ParamsAnotherRequest()
				
					--mobile side: sending ResetGlobalProperties request
					local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
					{
						mainField1 ="Show1",
						properties = 
						{
							"VRHELPTITLE",
							"MENUNAME",
							"MENUICON",
							"KEYBOARDPROPERTIES",
							"VRHELPITEMS",
							"HELPPROMPT",
							"TIMEOUTPROMPT"
						}
					})
					--hmi side: expect TTS.SetGlobalProperties request
					EXPECT_HMICALL("TTS.SetGlobalProperties",
					{
						--[=[ TODO: update after resolving APPLINK-9734
						helpPrompt = 
						{
							{
								type = "TEXT",
								text = textPromtValue[1]
							},
							{
								type = "TEXT",
								text = textPromtValue[2]
							}
						},]=]
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
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending TTS.SetGlobalProperties response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)
					:ValidIf(function(_,data)
						if data.params.mainField1 then 
							print ("\27[35m Request came with fake parameter \27[0m")
							return false
						else
							return true
						end
					end)
				

					--hmi side: expect UI.SetGlobalProperties request
					EXPECT_HMICALL("UI.SetGlobalProperties",
					{
						menuTitle = title_to_check,
						menuIcon = {
										imageType = "DYNAMIC",
										value = icon_to_check
									},
						vrHelpTitle = "Test Application",
						keyboardProperties = 
						{
							keyboardLayout = "QWERTY",
							autoCompleteText = "",
							language = "EN-US"
						},
						vrHelp = nil
					})
					
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)
					:ValidIf(function(_,data)
						if data.params.mainField1 then 
							print ("\27[35m Request came with fake parameter \27[0m")
							return false
						else
							return true
						end
					end)				

					--mobile side: expect SetGlobalProperties response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
					:Timeout(iTimeout)
					
					EXPECT_NOTIFICATION("OnHashChange")
					:Timeout(iTimeout)
				end

			--End Test case CommonRequestCheck.7.2			
		--End Test case CommonRequestCheck.7	

		-----------------------------------------------------------------------------------------

		--Begin Test case CommonRequestCheck.8
		--Description: Check request is sent with invalid JSON structure		
		
			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-395

			--Verification criteria: The request with wrong JSON syntax is sent, the response comes with INVALID_DATA result code.
			
				-- missing ':' after properties
				local Payload          = '{"properties" ["HELPPROMPT","TIMEOUTPROMPT","VRHELPTITLE","VRHELPITEMS","MENUICON","MENUNAME","KEYBOARDPROPERTIES"]}'
						
				commonTestCases:VerifyInvalidJsonRequest(4, Payload)

		--End Test case CommonRequestCheck.8
		
		-----------------------------------------------------------------------------------------
--TODO: Update requirement, Verification criteria
		--Begin Test case CommonRequestCheck.9
		--Description: check requests with duplicate correlation id
			
				--Requirement id in JAMA/or Jira ID: 

				--Verification criteria:

				function Test:ResetGlobalProperties_DuplicateCorrelationID()
				
					--mobile side: sending ResetGlobalProperties request
					local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
					{
						properties = 
						{
							"VRHELPTITLE",
							"MENUNAME",
							"MENUICON",
							"KEYBOARDPROPERTIES",
							"VRHELPITEMS",
							"HELPPROMPT",
							"TIMEOUTPROMPT"
						}
					})

					local msg = 
					{
						serviceType      = 7,
						frameInfo        = 0,
						rpcType          = 0,
						rpcFunctionId    = 4, --ResetGlobalPropertiesID
						rpcCorrelationId = cid,
						payload          = '{"properties":["HELPPROMPT","TIMEOUTPROMPT","VRHELPTITLE","VRHELPITEMS","MENUICON","MENUNAME","KEYBOARDPROPERTIES"]}'					
					}

					--hmi side: expect TTS.SetGlobalProperties request
					EXPECT_HMICALL("TTS.SetGlobalProperties")
						:Do(function(exp,data)
							if exp.occurences == 1 then
								self.mobileSession:Send(msg)
							end

							--hmi side: sending TTS.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						:Times(2)				

					--hmi side: expect UI.SetGlobalProperties request
					EXPECT_HMICALL("UI.SetGlobalProperties")
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						:Times(2)
					
					self.mobileSession:ExpectResponse(self.mobileSession.correlationId, { success = true, resultCode = "SUCCESS" })
						:Times(2)
					
					EXPECT_NOTIFICATION("OnHashChange")
						:Times(2)
					
				end

		--End Test case CommonRequestCheck.9	
	--End Test suit CommonRequestCheck	
	


---------------------------------------------------------------------------------------------
----------------------------------------II TEST BLOCK----------------------------------------
----------------------------------------Positive cases---------------------------------------
---------------------------------------------------------------------------------------------

	--=================================================================================--
	--------------------------------Positive request check-------------------------------
	--=================================================================================--


		--Begin Test suit PositiveRequestCheck
		--Description: check of each request parameter value in bound and boundary conditions
		
			--Requirement id in JAMA/or Jira ID: 
				--SDLAQ-CRS-394
				--SDLAQ-CRS-860
				--SDLAQ-CRS-1069
				--SDLAQ-CRS-2906
				--SDLAQ-CRS-1070
				--APPLINK-8589
				
			--Verification criteria:  
				--The request ResetGlobalProperties is sent and executed successfully. A reset has been made. The SUCCESS response code is returned. 
				--The TIMEOUTPROMPT global property default value should be platform dependent.
				--TIMEOUTPROMPT default values should be set up in SDL configuration ini file. By default it should be the same as HELPPROMPT.
				--By default vrHelpTitle value is set to application name.
				--By default vrHelpItems values are set to all the 1st VR commands of the current application and app's VR synonym.
				--SDL must reset VRHELPITEM together with VRHELPTITLE requested, and visa versa
				
			--Begin Test case PositiveResponseCheck.1
			--Description: Check properties parameter is HELPPROMPT

				function Test:ResetGlobalProperties_properties_HELPPROMPT()
				
					--mobile side: sending ResetGlobalProperties request
					local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
															{
																properties = 
																{
																	"HELPPROMPT"
																}
															})

					--hmi side: expect TTS.SetGlobalProperties request
					EXPECT_HMICALL("TTS.SetGlobalProperties",
									{
										--[=[ TODO: update after resolving APPLINK-9734
										helpPrompt = 
										{
											{
												type = "TEXT",
												text = "Please speak one of the following commands,"
											},
											{
												type = "TEXT",
												text = "Please say a command,"
											}
										}]=]
									})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending TTS.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)

				
					--mobile side: expect SetGlobalProperties response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
						:Timeout(iTimeout)
					
					EXPECT_NOTIFICATION("OnHashChange")
						:Timeout(iTimeout)
					
				end

			--End Test case PositiveResponseCheck.1
			
			-----------------------------------------------------------------------------------------

			--Begin Test case PositiveResponseCheck.2
			--Description: Check properties parameter is TIMEOUTPROMPT

				function Test:ResetGlobalProperties_properties_TIMEOUTPROMPT()
				
					--mobile side: sending ResetGlobalProperties request
					local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
					{
						properties = 
						{
							"TIMEOUTPROMPT"
						}
					})
					--hmi side: expect TTS.SetGlobalProperties request
					EXPECT_HMICALL("TTS.SetGlobalProperties",
					{
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
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending TTS.SetGlobalProperties response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)

				
					--mobile side: expect SetGlobalProperties response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
					:Timeout(iTimeout)
					
					EXPECT_NOTIFICATION("OnHashChange")
					:Timeout(iTimeout)
				end

			--End Test case PositiveResponseCheck.2
			
			-----------------------------------------------------------------------------------------

			--Begin Test case PositiveResponseCheck.3
			--Description: Check properties parameter is VRHELPTITLE
			
				function Test:ResetGlobalProperties_properties_VRHELPTITLE()
				
					--mobile side: sending ResetGlobalProperties request
					local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
					{
						properties = 
						{
							"VRHELPTITLE"
						}
					})
					

					--hmi side: expect UI.SetGlobalProperties request
					EXPECT_HMICALL("UI.SetGlobalProperties",
					{
						vrHelpTitle = "Test Application",
						vrHelp = nil					
					})
					
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)

				

					--mobile side: expect SetGlobalProperties response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
					:Timeout(iTimeout)
					
					EXPECT_NOTIFICATION("OnHashChange")
					:Timeout(iTimeout)
				end

			--End Test case PositiveResponseCheck.3
			
			-----------------------------------------------------------------------------------------

			--Begin Test case PositiveResponseCheck.4
			--Description: Check properties parameter is VRHELPITEMS

				function Test:ResetGlobalProperties_properties_VRHELPITEMS()
				
					--mobile side: sending ResetGlobalProperties request
					local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
					{
						properties = 
						{
							"VRHELPITEMS"
						}
					})
					
				

					--hmi side: expect UI.SetGlobalProperties request
					EXPECT_HMICALL("UI.SetGlobalProperties",
					{
						vrHelpTitle = "Test Application",
						vrHelp = nil					
					})			
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)

				

					--mobile side: expect SetGlobalProperties response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
					:Timeout(iTimeout)
					
					EXPECT_NOTIFICATION("OnHashChange")
					:Timeout(iTimeout)
				end

			--End Test case PositiveResponseCheck.4
			-----------------------------------------------------------------------------------------

			
			--Begin Test case PositiveResponseCheck.5
			--Description: Check properties parameter is MENUNAME

				function Test:ResetGlobalProperties_properties_MENUNAME()
				
					--mobile side: sending ResetGlobalProperties request
					local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
					{
						properties = 
						{
							"MENUNAME"
						}
					})
					
				

					--hmi side: expect UI.SetGlobalProperties request
					EXPECT_HMICALL("UI.SetGlobalProperties",
					{
						menuTitle = ""
					})			
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)

				

					--mobile side: expect SetGlobalProperties response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
					:Timeout(iTimeout)
					
					EXPECT_NOTIFICATION("OnHashChange")
					:Timeout(iTimeout)
				end

			--End Test case PositiveResponseCheck.5
			-----------------------------------------------------------------------------------------
			
			
			--Begin Test case PositiveResponseCheck.6
			--Description: Check properties parameter is MENUICON

				function Test:ResetGlobalProperties_properties_MENUICON()
				
					--mobile side: sending ResetGlobalProperties request
					local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
					{
						properties = 
						{
							"MENUICON"
						}
					})
					
				

					--hmi side: expect UI.SetGlobalProperties request
					EXPECT_HMICALL("UI.SetGlobalProperties",
					{
					})			
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)

				

					--mobile side: expect SetGlobalProperties response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
					:Timeout(iTimeout)
					
					EXPECT_NOTIFICATION("OnHashChange")
					:Timeout(iTimeout)
				end

			--End Test case PositiveResponseCheck.6
			-----------------------------------------------------------------------------------------
				
			--Begin Test case PositiveResponseCheck.7
			--Description: Check properties parameter is KEYBOARDPROPERTIES

				function Test:ResetGlobalProperties_properties_KEYBOARDPROPERTIES()
				
					--mobile side: sending ResetGlobalProperties request
					local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
					{
						properties = 
						{
							"KEYBOARDPROPERTIES"
						}
					})
					
				

					--hmi side: expect UI.SetGlobalProperties request
					EXPECT_HMICALL("UI.SetGlobalProperties",
					{
						keyboardProperties = 
						{
							keyboardLayout = "QWERTY",
							autoCompleteText = "",
							language = "EN-US"
						}
					})
					
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)

				
					--mobile side: expect SetGlobalProperties response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
					:Timeout(iTimeout)
					
					EXPECT_NOTIFICATION("OnHashChange")
					:Timeout(iTimeout)
				end

			--End Test case PositiveResponseCheck.7
			-----------------------------------------------------------------------------------------
			
			--Begin Test case PositiveResponseCheck.8
			--Description: Check properties parameter is maxsize

				function Test:ResetGlobalProperties_properties_Is_maxsize_Of_OneValue()
				
					--mobile side: sending ResetGlobalProperties request
					local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
					{
						properties = 
						{
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
							"MENUNAME",
						}
					})
					

					--hmi side: expect UI.SetGlobalProperties request
					EXPECT_HMICALL("UI.SetGlobalProperties",
					{
						menuTitle = "",					
					})
					
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)

				

					--mobile side: expect SetGlobalProperties response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
					:Timeout(iTimeout)
					
					EXPECT_NOTIFICATION("OnHashChange")
					:Timeout(iTimeout)
				end

			--End Test case PositiveResponseCheck.8
			-----------------------------------------------------------------------------------------

			--Begin Test case PositiveResponseCheck.9
			--Description: Check properties parameter is maxsize

				function Test:ResetGlobalProperties_properties_Is_maxsize_Of_SomeValue()
				
					--mobile side: sending ResetGlobalProperties request
					local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
															{
																properties = 
																{
																	"VRHELPTITLE",
																	"MENUNAME",
																	"MENUICON",
																	"KEYBOARDPROPERTIES",
																	"VRHELPITEMS",
																	"HELPPROMPT",
																	"TIMEOUTPROMPT",
																	"VRHELPTITLE",
																	"MENUNAME",
																	"MENUICON",
																	"KEYBOARDPROPERTIES",
																	"VRHELPITEMS",
																	"HELPPROMPT",
																	"TIMEOUTPROMPT",
																	"VRHELPTITLE",
																	"MENUNAME",
																	"MENUICON",
																	"KEYBOARDPROPERTIES",
																	"VRHELPITEMS",
																	"HELPPROMPT",
																	"TIMEOUTPROMPT",
																	"VRHELPTITLE",
																	"MENUNAME",
																	"MENUICON",
																	"KEYBOARDPROPERTIES",
																	"VRHELPITEMS",
																	"HELPPROMPT",
																	"TIMEOUTPROMPT",
																	"VRHELPTITLE",
																	"MENUNAME",
																	"MENUICON",
																	"KEYBOARDPROPERTIES",
																	"VRHELPITEMS",
																	"HELPPROMPT",
																	"TIMEOUTPROMPT",
																	"VRHELPTITLE",
																	"MENUNAME",
																	"MENUICON",
																	"KEYBOARDPROPERTIES",
																	"VRHELPITEMS",
																	"HELPPROMPT",
																	"TIMEOUTPROMPT",
																	"VRHELPTITLE",
																	"MENUNAME",
																	"MENUICON",
																	"KEYBOARDPROPERTIES",
																	"VRHELPITEMS",
																	"HELPPROMPT",
																	"TIMEOUTPROMPT",
																	"VRHELPTITLE",
																	"MENUNAME",
																	"MENUICON",
																	"KEYBOARDPROPERTIES",
																	"VRHELPITEMS",
																	"HELPPROMPT",
																	"TIMEOUTPROMPT",
																	"VRHELPTITLE",
																	"MENUNAME",
																	"MENUICON",
																	"KEYBOARDPROPERTIES",
																	"VRHELPITEMS",
																	"HELPPROMPT",
																	"TIMEOUTPROMPT",
																	"VRHELPTITLE",
																	"MENUNAME",
																	"MENUICON",
																	"KEYBOARDPROPERTIES",
																	"VRHELPITEMS",
																	"HELPPROMPT",
																	"TIMEOUTPROMPT",
																	"VRHELPTITLE",
																	"MENUNAME",
																	"MENUICON",
																	"KEYBOARDPROPERTIES",
																	"VRHELPITEMS",
																	"HELPPROMPT",
																	"TIMEOUTPROMPT",
																	"VRHELPTITLE",
																	"MENUNAME",
																	"MENUICON",
																	"KEYBOARDPROPERTIES",
																	"VRHELPITEMS",
																	"HELPPROMPT",
																	"TIMEOUTPROMPT",
																	"VRHELPTITLE",
																	"MENUNAME",
																	"MENUICON",
																	"KEYBOARDPROPERTIES",
																	"VRHELPITEMS",
																	"HELPPROMPT",
																	"TIMEOUTPROMPT",
																	"VRHELPTITLE",
																	"MENUNAME",
																	"MENUICON",
																	"KEYBOARDPROPERTIES",
																	"VRHELPITEMS",
																	"HELPPROMPT",
																	"TIMEOUTPROMPT",
																	"VRHELPTITLE",
																	"VRHELPTITLE"
																}
															})
					

					--hmi side: expect TTS.SetGlobalProperties request
					EXPECT_HMICALL("TTS.SetGlobalProperties",
									{
									--[=[ TODO: update after resolving APPLINK-9734
										helpPrompt = 
										{
											{
												type = "TEXT",
												text = textPromtValue[1]
											},
											{
												type = "TEXT",
												text = textPromtValue[2]
											}
										},]=]
										timeoutPrompt = 
										{
											{
												type = "TEXT",
												text = "Please speak one of the following commands,"
											},
											{
												type = "TEXT",
												text = "Please say a command,"
											}
										}
									})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending TTS.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)

				

					--hmi side: expect UI.SetGlobalProperties request
					EXPECT_HMICALL("UI.SetGlobalProperties",
									{
										menuTitle = title_to_check,
										menuIcon = {
														imageType = "DYNAMIC",
														value = icon_to_check
													},
										vrHelpTitle = "Test Application",
										keyboardProperties = 
										{
											keyboardLayout = "QWERTY",
											autoCompleteText = "",
											language = "EN-US"
										}
									})
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
				

					--mobile side: expect SetGlobalProperties response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
						:Timeout(iTimeout)
					
					EXPECT_NOTIFICATION("OnHashChange")
						:Timeout(iTimeout)
				end

			--End Test case PositiveResponseCheck.9
			-----------------------------------------------------------------------------------------

			--Begin Test case PositiveResponseCheck.10
			--Description: Reset vrHelpItems for app has VR synonym
					
				function Test:ActivateSecondApplication()
					--HMI send ActivateApp request
					local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.appID2})
					EXPECT_HMIRESPONSE(RequestId)
					:Do(function(_,data)
						if data.result.isSDLAllowed ~= true then
							local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
							EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
							:Do(function(_,data)
								--hmi side: send request SDL.OnAllowSDLFunctionality
								self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})
							end)

							EXPECT_HMICALL("BasicCommunication.ActivateApp")
							:Do(function(_,data)
								self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
							end)
							:Times(2)
						end
					end)

					self.mobileSession2:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", systemContext = "MAIN"})

				end
		
				
				function Test:ResetGlobalProperties_vrHelpItemsVRsynonym()
				
					--mobile side: sending ResetGlobalProperties request
					local cid = self.mobileSession2:SendRPC("ResetGlobalProperties",
					{
						properties = 
						{
							"VRHELPITEMS",	
						}
					})
					

					--hmi side: expect UI.SetGlobalProperties request
					EXPECT_HMICALL("UI.SetGlobalProperties",
					{
						vrHelpTitle = "Test Application2",
						vrHelp = 
						{
							{
								position = 1,
								text = "VRSyncProxyTester1"
							}
						}						
					})			
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)

					--mobile side: expect SetGlobalProperties response
					self.mobileSession2:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
					:Timeout(iTimeout)
					
					self.mobileSession2:ExpectNotification("OnHashChange", {})
					:Timeout(iTimeout)
				end

					
				function Test:ActivateFirstApplication()
					--HMI send ActivateApp request
					local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"]})
					EXPECT_HMIRESPONSE(RequestId)
					:Do(function(_,data)
						if data.result.isSDLAllowed ~= true then
							local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
							EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
							:Do(function(_,data)
								--hmi side: send request SDL.OnAllowSDLFunctionality
								self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})
							end)

							EXPECT_HMICALL("BasicCommunication.ActivateApp")
							:Do(function(_,data)
								self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
							end)
							:Times(2)
						end
					end)

					self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
					self.mobileSession2:ExpectNotification("OnHMIStatus",{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

				end
		
			--End Test case PositiveResponseCheck.10
			-----------------------------------------------------------------------------------------
			
			--Begin Test case PositiveResponseCheck.11
			--Description: Reset vrHelpItem for app has not VR synonym
			
				function Test:ResetGlobalProperties_VRHELPITEMS_without_vrSynonym()
				
					--mobile side: sending ResetGlobalProperties request
					local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
					{
						properties = 
						{
							"VRHELPITEMS"
						}
					})
					
					--hmi side: expect UI.SetGlobalProperties request
					EXPECT_HMICALL("UI.SetGlobalProperties",
					{
						vrHelpTitle = "Test Application",
					})			
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)
					:ValidIf(function(_,data)
						if data.params.vrHelp then 
							print ("\27[35m Request came with vrHelp parameter \27[0m")
							return false
						else
							return true
						end
					end)
				
					--mobile side: expect SetGlobalProperties response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
					:Timeout(iTimeout)
					
					EXPECT_NOTIFICATION("OnHashChange")
					:Timeout(iTimeout)
				end

			--End Test case PositiveResponseCheck.11
			-----------------------------------------------------------------------------------------

			--Begin Test case PositiveResponseCheck.12
			--Description: Reset vrHelpItem for app has not VR synonym but has AddCommand with serveral vrSynonyms
			
			--From App1: Add Command
				function Test:AddCommand_vrSynonyms_App1()
						--mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
																{
																	cmdID = 11,
																	
																	vrCommands = 
																	{ 
																		"VRCommand1",
																		"VRCommand2"
																	}, 
																	
																})
						--hmi side: expect UI.AddCommand request
						EXPECT_HMICALL("UI.AddCommand", 
										{ 
											cmdID = 11
											
										})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						:Times(0)
							
						--hmi side: expect VR.AddCommand request
						EXPECT_HMICALL("VR.AddCommand", 
										{ 
											cmdID = 11,
											type = "Command",
											vrCommands = 
											{
												"VRCommand1", 
												"VRCommand2"
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
					end
				
			--Reset vrHelpItem
				function Test:ResetGlobalProperties_VRHELPITEMS_without_vrSynonym_with_VrCommands()
				
					--mobile side: sending ResetGlobalProperties request
					local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
					{
						properties = 
						{
							"VRHELPITEMS"
						}
					})
					
					--hmi side: expect UI.SetGlobalProperties request
					EXPECT_HMICALL("UI.SetGlobalProperties",
					{
						vrHelpTitle = "Test Application",
						vrHelp = 
						{
							{
								position = 1,
								text = "VRCommand1"
							}
						}	
					})			
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						--print("XXXXXXXXXXX"..#vrHelp)
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)
							
					--mobile side: expect SetGlobalProperties response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
					:Timeout(iTimeout)
					
					EXPECT_NOTIFICATION("OnHashChange")
					:Timeout(iTimeout)
				end
				
			--End Test case PositiveResponseCheck.12
			-----------------------------------------------------------------------------------------
				
			--Begin Test case PositiveResponseCheck.13
			--Description: Reset vrHelpItem for app has VR synonym and has AddCommand with serveral vrSynonyms
			
			--Activate App2 
				function Test:ActivateSecondApplication()
					--HMI send ActivateApp request
					local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.appID2})
					EXPECT_HMIRESPONSE(RequestId)
					:Do(function(_,data)
						if data.result.isSDLAllowed ~= true then
							local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
							EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
							:Do(function(_,data)
								--hmi side: send request SDL.OnAllowSDLFunctionality
								self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})
							end)

							EXPECT_HMICALL("BasicCommunication.ActivateApp")
							:Do(function(_,data)
								self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
							end)
							:Times(2)
						end
					end)

					self.mobileSession2:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", systemContext = "MAIN"})

				end

			--From App2: Add Command
				function Test:AddCommand_vrSynonyms_App2()
					--mobile side: sending AddCommand request
					local cid = self.mobileSession2:SendRPC("AddCommand",
															{
																cmdID = 11,
																
																vrCommands = 
																{ 
																	"VRCommand1",
																	"VRCommand2"
																}, 
																
															})
					--hmi side: expect UI.AddCommand request
					EXPECT_HMICALL("UI.AddCommand", 
									{ 
										cmdID = 11
										
									})
					:Do(function(_,data)
						--hmi side: sending UI.AddCommand response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)
					:Times(0)
						
					--hmi side: expect VR.AddCommand request
					EXPECT_HMICALL("VR.AddCommand", 
									{ 
										cmdID = 11,
										type = "Command",
										vrCommands = 
										{
											"VRCommand1", 
											"VRCommand2"
										}
									})
					:Do(function(_,data)
						--hmi side: sending VR.AddCommand response						
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)
					
					--mobile side: expect AddCommand response
					self.mobileSession2:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
					
					--mobile side: expect OnHashChange notification
					--self.mobileSession2:ExpectNotification("OnHashChange")
				end

			--Reset VRHELPITEMS
				function Test:ResetGlobalProperties_VRHELPITEMS_with_vrSynonyms_with_VrCommands_()
					--mobile side: sending ResetGlobalProperties request
					local cid = self.mobileSession2:SendRPC("ResetGlobalProperties",
					{
						properties = 
						{
							"VRHELPITEMS",	
						}
					})
					
					--hmi side: expect UI.SetGlobalProperties request
					EXPECT_HMICALL("UI.SetGlobalProperties",
					{
						vrHelpTitle = "Test Application2",
						vrHelp = 
						{
							{
								position = 1,
								text = "VRSyncProxyTester1"
							},
							{
								position = 2,
								text = "VRCommand1"
							}
						}						
					})			
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)

					--mobile side: expect SetGlobalProperties response
					self.mobileSession2:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
					:Timeout(iTimeout)
					
					self.mobileSession2:ExpectNotification("OnHashChange", {})
					:Timeout(iTimeout)
				end

			--End Test case PositiveResponseCheck.13
			
		--End Test suit PositiveRequestCheck
	
	
	--=================================================================================--
	--------------------------------Positive response check------------------------------
	--=================================================================================--

		--------Checks-----------
		-- parameters with values in boundary conditions

		
		--Begin Test suit PositiveResponseCheck
		--Description: Check positive responses 
		
			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-17, APPLINK-13276

			--Verification criteria: ResetGlobalProperties responses contains info parameter with minlength

			--Begin Test case PositiveResponseCheck.1
			--Description: Check info parameter when TTS.SetGlobalProperties response with minlength
				
				function Test:ResetGlobalProperties_TTS_Response_Infor_1_char()
				
					--mobile side: sending ResetGlobalProperties request
					local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
					{
						properties = 
						{
							"VRHELPTITLE",
							"MENUNAME",
							"MENUICON",
							"KEYBOARDPROPERTIES",
							"VRHELPITEMS",
							"HELPPROMPT",
							"TIMEOUTPROMPT"
						}
					})
					--hmi side: expect TTS.SetGlobalProperties request
					EXPECT_HMICALL("TTS.SetGlobalProperties", {})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending TTS.SetGlobalProperties response
						--self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {massage = "a"})
						--UPDATED
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = "a"})
					end)

				

					--hmi side: expect UI.SetGlobalProperties request
					EXPECT_HMICALL("UI.SetGlobalProperties", {})
					
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)

				

					--mobile side: expect SetGlobalProperties response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", info = "a"})
					:Timeout(iTimeout)
					
					EXPECT_NOTIFICATION("OnHashChange")
					:Timeout(iTimeout)
				end

			--End Test case PositiveResponseCheck.1
			-----------------------------------------------------------------------------------------

			--Begin Test case PositiveResponseCheck.2
			--Description: Check info parameter when UI.SetGlobalProperties response with minlength

				function Test:ResetGlobalProperties_UI_Response_Infor_1_char()
				
					--mobile side: sending ResetGlobalProperties request
					local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
					{
						properties = 
						{
							"VRHELPTITLE",
							"MENUNAME",
							"MENUICON",
							"KEYBOARDPROPERTIES",
							"VRHELPITEMS",
							"HELPPROMPT",
							"TIMEOUTPROMPT"
						}
					})
					--hmi side: expect TTS.SetGlobalProperties request
					EXPECT_HMICALL("TTS.SetGlobalProperties", {})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending TTS.SetGlobalProperties response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)

				

					--hmi side: expect UI.SetGlobalProperties request
					EXPECT_HMICALL("UI.SetGlobalProperties", {})
					
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						--self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {massage = "a"})
						--UPDATED
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = "a"})
					end)

				

					--mobile side: expect SetGlobalProperties response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", info = "a"})
					:Timeout(iTimeout)
					
					EXPECT_NOTIFICATION("OnHashChange")
					:Timeout(iTimeout)
				end

			--End Test case PositiveResponseCheck.2
			-----------------------------------------------------------------------------------------
					
			--Begin Test case PositiveResponseCheck.3
			--Description: Check info parameter when both TTS and UI send SetGlobalProperties responses with minlength

				function Test:ResetGlobalProperties_TTS_and_UI_Response_Infor_1_char()
				
					--mobile side: sending ResetGlobalProperties request
					local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
					{
						properties = 
						{
							"VRHELPTITLE",
							"MENUNAME",
							"MENUICON",
							"KEYBOARDPROPERTIES",
							"VRHELPITEMS",
							"HELPPROMPT",
							"TIMEOUTPROMPT"
						}
					})
					--hmi side: expect TTS.SetGlobalProperties request
					EXPECT_HMICALL("TTS.SetGlobalProperties", {})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending TTS.SetGlobalProperties response
						--self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {massage = "b"})
						--UPDATED
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = "b"})
					end)

				

					--hmi side: expect UI.SetGlobalProperties request
					EXPECT_HMICALL("UI.SetGlobalProperties", {})
					
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						--self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {massage = "a"})
						--UPDATED
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = "a"})
					end)

				

					--mobile side: expect SetGlobalProperties response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", info = "b. a"})
					:Timeout(iTimeout)
					
					EXPECT_NOTIFICATION("OnHashChange")
					:Timeout(iTimeout)
				end

			--End Test case PositiveResponseCheck.3
			-----------------------------------------------------------------------------------------
				
					
			--Begin Test case PositiveResponseCheck.4
			--Description: Check info parameter when TTS.SetGlobalProperties response with maxlength

				function Test:ResetGlobalProperties_TTS_Response_Infor_1000_chars()
				
					
					--mobile side: sending ResetGlobalProperties request
					local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
					{
						properties = 
						{
							"VRHELPTITLE",
							"MENUNAME",
							"MENUICON",
							"KEYBOARDPROPERTIES",
							"VRHELPITEMS",
							"HELPPROMPT",
							"TIMEOUTPROMPT"
						}
					})
					--hmi side: expect TTS.SetGlobalProperties request
					EXPECT_HMICALL("TTS.SetGlobalProperties", {})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending TTS.SetGlobalProperties response
						--self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {massage = str1000Chars})
						--UPDATED
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = str1000Chars})
					end)

				

					--hmi side: expect UI.SetGlobalProperties request
					EXPECT_HMICALL("UI.SetGlobalProperties", {})
					
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)

				

					--mobile side: expect SetGlobalProperties response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", info = str1000Chars})
					:Timeout(iTimeout)
					
					EXPECT_NOTIFICATION("OnHashChange")
					:Timeout(iTimeout)
				end

			--End Test case PositiveResponseCheck.4
			-----------------------------------------------------------------------------------------

			--Begin Test case PositiveResponseCheck.5
			--Description: Check info parameter when UI.SetGlobalProperties response with maxlength

				function Test:ResetGlobalProperties_UI_Response_Infor_1000_chars()
				

					--mobile side: sending ResetGlobalProperties request
					local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
					{
						properties = 
						{
							"VRHELPTITLE",
							"MENUNAME",
							"MENUICON",
							"KEYBOARDPROPERTIES",
							"VRHELPITEMS",
							"HELPPROMPT",
							"TIMEOUTPROMPT"
						}
					})
					--hmi side: expect TTS.SetGlobalProperties request
					EXPECT_HMICALL("TTS.SetGlobalProperties", {})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending TTS.SetGlobalProperties response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)

				

					--hmi side: expect UI.SetGlobalProperties request
					EXPECT_HMICALL("UI.SetGlobalProperties", {})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						--self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {massage = str1000Chars})
						--UPDATED
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = str1000Chars})
					end)

				

					--mobile side: expect SetGlobalProperties response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", info = str1000Chars})
					:Timeout(iTimeout)

					EXPECT_NOTIFICATION("OnHashChange")
					:Timeout(iTimeout)
				end

			--End Test case PositiveResponseCheck.5
			-----------------------------------------------------------------------------------------
			
			--Begin Test case PositiveResponseCheck.6
			--Description: Check info parameter when UI and TTS send SetGlobalProperties response with maxlength

				function Test:ResetGlobalProperties_UI_and_TTS_Response_Infor_1000_chars()
				
					
					--mobile side: sending ResetGlobalProperties request
					local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
					{
						properties = 
						{
							"VRHELPTITLE",
							"MENUNAME",
							"MENUICON",
							"KEYBOARDPROPERTIES",
							"VRHELPITEMS",
							"HELPPROMPT",
							"TIMEOUTPROMPT"
						}
					})
					--hmi side: expect TTS.SetGlobalProperties request
					EXPECT_HMICALL("TTS.SetGlobalProperties", {})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending TTS.SetGlobalProperties response
						--self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {massage = str1000Chars})
						--UPDATED
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = str1000Chars})
					end)

				

					--hmi side: expect UI.SetGlobalProperties request
					EXPECT_HMICALL("UI.SetGlobalProperties", {})
					
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						--self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {massage = str1000Chars2})
						--UPDATED
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = str1000Chars2})
					end)

				

					--mobile side: expect SetGlobalProperties response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", info = str1000Chars})
					:Timeout(iTimeout)
					
					EXPECT_NOTIFICATION("OnHashChange")
					:Timeout(iTimeout)
				end

			--End Test case PositiveResponseCheck.5
		--End Test suit PositiveResponseCheck
		

----------------------------------------------------------------------------------------------
----------------------------------------III TEST BLOCK----------------------------------------
----------------------------------------Negative cases----------------------------------------
----------------------------------------------------------------------------------------------

	--=================================================================================--
	---------------------------------Negative request check------------------------------
	--=================================================================================--
		--------Checks-----------
		-- outbound values
		-- invalid values(empty, missing, nonexistent, duplicate, invalid characters)
		-- parameters with wrong type
		-- invalid json

	--Begin Test suit NegativeRequestCheck
	--Description: check of each request parameter value out of bound, missing, with wrong type, empty, duplicate etc.

	
		--Begin Test suit NegativeRequestCheck.1
		--Description: check of each request parameter value out of bound
		
		
			--Begin Test case NegativeRequestCheck.1.1
			--Description: Check properties parameter is outlower bound values

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-18

				--Verification criteria: ResetGlobalProperties request resets the requested GlobalProperty values to default ones.

				function Test:ResetGlobalProperties_properties_IsOutLowerBound()
				
					--mobile side: sending ResetGlobalProperties request
					local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
					{
						properties = {}
					})
					
					--mobile side: expect SetGlobalProperties response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
					:Timeout(iTimeout)
					
					EXPECT_NOTIFICATION("OnHashChange")
					:Timeout(12000)
					:Times(0)			
				end
	
			--End Test case NegativeRequestCheck.1.1
			-----------------------------------------------------------------------------------------

			
			--Begin Test case NegativeRequestCheck.1.2
			--Description: Check properties parameter is out upper bound values

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-18

				--Verification criteria: ResetGlobalProperties request resets the requested GlobalProperty values to default ones.
				
				function Test:ResetGlobalProperties_properties_IsOutUpperBound()
				
					--mobile side: sending ResetGlobalProperties request
					local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
					{
						properties = 
						{
							"VRHELPTITLE",
							"MENUNAME",
							"MENUICON",
							"KEYBOARDPROPERTIES",
							"VRHELPITEMS",
							"HELPPROMPT",
							"TIMEOUTPROMPT",
							"VRHELPTITLE",
							"MENUNAME",
							"MENUICON",
							"KEYBOARDPROPERTIES",
							"VRHELPITEMS",
							"HELPPROMPT",
							"TIMEOUTPROMPT",
							"VRHELPTITLE",
							"MENUNAME",
							"MENUICON",
							"KEYBOARDPROPERTIES",
							"VRHELPITEMS",
							"HELPPROMPT",
							"TIMEOUTPROMPT",
							"VRHELPTITLE",
							"MENUNAME",
							"MENUICON",
							"KEYBOARDPROPERTIES",
							"VRHELPITEMS",
							"HELPPROMPT",
							"TIMEOUTPROMPT",
							"VRHELPTITLE",
							"MENUNAME",
							"MENUICON",
							"KEYBOARDPROPERTIES",
							"VRHELPITEMS",
							"HELPPROMPT",
							"TIMEOUTPROMPT",
							"VRHELPTITLE",
							"MENUNAME",
							"MENUICON",
							"KEYBOARDPROPERTIES",
							"VRHELPITEMS",
							"HELPPROMPT",
							"TIMEOUTPROMPT",
							"VRHELPTITLE",
							"MENUNAME",
							"MENUICON",
							"KEYBOARDPROPERTIES",
							"VRHELPITEMS",
							"HELPPROMPT",
							"TIMEOUTPROMPT",
							"VRHELPTITLE",
							"MENUNAME",
							"MENUICON",
							"KEYBOARDPROPERTIES",
							"VRHELPITEMS",
							"HELPPROMPT",
							"TIMEOUTPROMPT",
							"VRHELPTITLE",
							"MENUNAME",
							"MENUICON",
							"KEYBOARDPROPERTIES",
							"VRHELPITEMS",
							"HELPPROMPT",
							"TIMEOUTPROMPT",
							"VRHELPTITLE",
							"MENUNAME",
							"MENUICON",
							"KEYBOARDPROPERTIES",
							"VRHELPITEMS",
							"HELPPROMPT",
							"TIMEOUTPROMPT",
							"VRHELPTITLE",
							"MENUNAME",
							"MENUICON",
							"KEYBOARDPROPERTIES",
							"VRHELPITEMS",
							"HELPPROMPT",
							"TIMEOUTPROMPT",
							"VRHELPTITLE",
							"MENUNAME",
							"MENUICON",
							"KEYBOARDPROPERTIES",
							"VRHELPITEMS",
							"HELPPROMPT",
							"TIMEOUTPROMPT",
							"VRHELPTITLE",
							"MENUNAME",
							"MENUICON",
							"KEYBOARDPROPERTIES",
							"VRHELPITEMS",
							"HELPPROMPT",
							"TIMEOUTPROMPT",
							"VRHELPTITLE",
							"MENUNAME",
							"MENUICON",
							"KEYBOARDPROPERTIES",
							"VRHELPITEMS",
							"HELPPROMPT",
							"TIMEOUTPROMPT",
							"VRHELPTITLE",
							"VRHELPTITLE",
							"VRHELPTITLE"
						}
					})
					
					--mobile side: expect SetGlobalProperties response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
					:Timeout(iTimeout)
					
					EXPECT_NOTIFICATION("OnHashChange")
					:Timeout(12000)
					:Times(0)				
				end

			--End Test case NegativeRequestCheck.1.2
			-----------------------------------------------------------------------------------------
	
		--End Test suit NegativeResponseCheck.1

		-----------------------------------------------------------------------------------------
		
		--Begin Test suit NegativeRequestCheck.2
		--Description: check of each request parameter value is invalid values(empty, missing, nonexistent, duplicate, invalid characters)

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-18

			--Verification criteria: ResetGlobalProperties request resets the requested GlobalProperty values to default ones.
			
			--Begin Test case NegativeRequestCheck.2.1
			--Description: Check properties parameter is empty

				function Test:ResetGlobalProperties_propertiesEmpty()
				
					--mobile side: sending ResetGlobalProperties request
					local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
					{
						properties = {""}
					})
					
					--mobile side: expect SetGlobalProperties response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
					:Timeout(iTimeout)
					
					EXPECT_NOTIFICATION("OnHashChange")
					:Timeout(12000)
					:Times(0)				
				end
				
			--End Test case NegativeRequestCheck.2.1
			-----------------------------------------------------------------------------------------

			
			--Begin Test case NegativeRequestCheck.2.2
			--Description: Check properties parameter is nonexistent

				function Test:ResetGlobalProperties_propertiesNonexistentValue()
				
					--mobile side: sending ResetGlobalProperties request
					local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
					{
						properties = {"nonexistent"}
					})
						
					--mobile side: expect SetGlobalProperties response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
					:Timeout(iTimeout)
					
					EXPECT_NOTIFICATION("OnHashChange")
					:Timeout(12000)
					:Times(0)				
				end
				
			--End Test case NegativeRequestCheck.2.2			
		--End Test suit NegativeRequestCheck.2	
		
		-----------------------------------------------------------------------------------------
		
		--Begin Test suit NegativeRequestCheck.3
		--Description: check of each request parameter value with wrong type
	
				function Test:ResetGlobalProperties_properties_IsWrongType()
				
					--mobile side: sending ResetGlobalProperties request
					local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
					{
						properties = 123
					})
					

					--mobile side: expect SetGlobalProperties response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
					:Timeout(iTimeout)
					
					EXPECT_NOTIFICATION("OnHashChange")
					:Timeout(12000)
					:Times(0)				
				end

		--End Test suit NegativeRequestCheck.3

		-----------------------------------------------------------------------------------------
		
		--Begin Test suit NegativeRequestCheck.4
		--Description: check of each request parameter value with wrong type
	
				function Test:ResetGlobalProperties_properties_element_IsWrongType()
				
					--mobile side: sending ResetGlobalProperties request
					local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
					{
						properties = {123}
					})
					

					--mobile side: expect SetGlobalProperties response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
					:Timeout(iTimeout)
					
					EXPECT_NOTIFICATION("OnHashChange")
					:Timeout(12000)
					:Times(0)				
				end

		--End Test suit NegativeRequestCheck.4

	--=================================================================================--
	---------------------------------Negative response check------------------------------
	--=================================================================================--

		--------Checks-----------
		-- outbound values
		-- invalid values(empty, missing, nonexistent, invalid characters)
		-- parameters with wrong type
		-- invalid json

		--Begin Test suit NegativeResponseCheck
		--Description: check negative response


			--Begin Test suit NegativeResponseCheck.1
			--Description: check negative response with outbound values

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-17, APPLINK-13276

				--Verification criteria: The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
				
				--Begin Test case NegativeResponseCheck.1.1
				--Description: TTS responses contains info parameter with out upper bound length=1001
--[[TODO: update after resolving APPLINK-14551
					function Test:ResetGlobalProperties_TTS_Response_Infor_1001_chars()


						local str1001Chars =  str1000Chars .."A"
						
						
						--mobile side: sending ResetGlobalProperties request
						local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
						{
							properties = 
							{
								"VRHELPTITLE",
								"MENUNAME",
								"MENUICON",
								"KEYBOARDPROPERTIES",
								"VRHELPITEMS",
								"HELPPROMPT",
								"TIMEOUTPROMPT"
							}
						})
						--hmi side: expect TTS.SetGlobalProperties request
						EXPECT_HMICALL("TTS.SetGlobalProperties", {})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending TTS.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = str1001Chars})
						end)

					

						--hmi side: expect UI.SetGlobalProperties request
						EXPECT_HMICALL("UI.SetGlobalProperties", {})
						
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)

					

						--mobile side: expect SetGlobalProperties response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", info = str1000Chars})
						:Timeout(iTimeout)
						
						EXPECT_NOTIFICATION("OnHashChange")	
						:Timeout(iTimeout)
					end

				--End Test case NegativeResponseCheck.1.1
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.1.2
				--Description: UI responses contains info parameter with out upper bound length=1001

					function Test:ResetGlobalProperties_UI_Response_Infor_1001_chars()
					
						local str1001Chars =  str1000Chars .."A"
						
						--mobile side: sending ResetGlobalProperties request
						local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
						{
							properties = 
							{
								"VRHELPTITLE",
								"MENUNAME",
								"MENUICON",
								"KEYBOARDPROPERTIES",
								"VRHELPITEMS",
								"HELPPROMPT",
								"TIMEOUTPROMPT"
							}
						})
						--hmi side: expect TTS.SetGlobalProperties request
						EXPECT_HMICALL("TTS.SetGlobalProperties", {})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending TTS.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)

					

						--hmi side: expect UI.SetGlobalProperties request
						EXPECT_HMICALL("UI.SetGlobalProperties", {})
						
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = str1001Chars})
						end)

					

						--mobile side: expect SetGlobalProperties response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", info = str1000Chars})
						:Timeout(iTimeout)
						
						EXPECT_NOTIFICATION("OnHashChange")	
						:Timeout(iTimeout)
					end

				--End Test case NegativeResponseCheck.1.2
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.1.3
				--Description: UI & TTS responses contains info parameter with out upper bound length=1001

					function Test:ResetGlobalProperties_Both_UI_And_TTS_Response_Infor_1001_chars()

						local str1000Chars_UI = str1000Chars

						local str1001Chars_UI =  str1000Chars_UI .."A"
						
						local str1000Chars_TTS = str1000Chars2

						local str1001Chars_TTS =  str1000Chars_TTS .."A"	
						
						--mobile side: sending ResetGlobalProperties request
						local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
						{
							properties = 
							{
								"VRHELPTITLE",
								"MENUNAME",
								"MENUICON",
								"KEYBOARDPROPERTIES",
								"VRHELPITEMS",
								"HELPPROMPT",
								"TIMEOUTPROMPT"
							}
						})
						--hmi side: expect TTS.SetGlobalProperties request
						EXPECT_HMICALL("TTS.SetGlobalProperties", {})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending TTS.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = str1001Chars_TTS})
						end)

					

						--hmi side: expect UI.SetGlobalProperties request
						EXPECT_HMICALL("UI.SetGlobalProperties", {})
						
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = str1001Chars_UI})
						end)

					

						--mobile side: expect SetGlobalProperties response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", info = str1000Chars_TTS})
						:Timeout(iTimeout)
						
						EXPECT_NOTIFICATION("OnHashChange")	
						:Timeout(iTimeout)
					end

				--End Test case NegativeResponseCheck.1.3
			--End Test suit NegativeResponseCheck.1

			-----------------------------------------------------------------------------------------
			
			--Begin Test suit NegativeResponseCheck.2
			--Description: check negative response with invalid values(empty, missing, nonexistent, invalid characters)
				
				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-17, APPLINK-13276

				--Verification criteria: SDL should not transfer empty "info" and invalid info to the app ("info" needs to be omitted).
			
				--Begin Test case NegativeResponseCheck.2.1
				--Description: check negative response from TTS with empty info

					function Test:ResetGlobalProperties_TTS_Response_Infor_empty()

						
						--mobile side: sending ResetGlobalProperties request
						local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
						{
							properties = 
							{
								"VRHELPTITLE",
								"MENUNAME",
								"MENUICON",
								"KEYBOARDPROPERTIES",
								"VRHELPITEMS",
								"HELPPROMPT",
								"TIMEOUTPROMPT"
							}
						})
						
						--hmi side: expect TTS.SetGlobalProperties request
						EXPECT_HMICALL("TTS.SetGlobalProperties", {})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending TTS.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = ""})
						end)

					

						--hmi side: expect UI.SetGlobalProperties request
						EXPECT_HMICALL("UI.SetGlobalProperties",
						{
							menuTitle = title_to_check,
							menuIcon = {
											imageType = "DYNAMIC",
											value = icon_to_check
										},
							vrHelpTitle = "Test Application",
							keyboardProperties = 
							{
								keyboardLayout = "QWERTY",
								autoCompleteText = "",
								language = "EN-US"
							}
						})
						
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)

					

						--mobile side: expect SetGlobalProperties response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", info = nil})
						:Timeout(iTimeout)
						
						EXPECT_NOTIFICATION("OnHashChange")	
						:Timeout(iTimeout)
					end

				--End Test case NegativeResponseCheck.2.1
				-----------------------------------------------------------------------------------------

				
				--Begin Test case NegativeResponseCheck.2.2
				--Description: check negative response from UI with empty info

					function Test:ResetGlobalProperties_UI_Response_Infor_empty()

						
						--mobile side: sending ResetGlobalProperties request
						local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
						{
							properties = 
							{
								"VRHELPTITLE",
								"MENUNAME",
								"MENUICON",
								"KEYBOARDPROPERTIES",
								"VRHELPITEMS",
								"HELPPROMPT",
								"TIMEOUTPROMPT"
							}
						})
						
						--hmi side: expect TTS.SetGlobalProperties request
						EXPECT_HMICALL("TTS.SetGlobalProperties", {})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending TTS.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)

					

						--hmi side: expect UI.SetGlobalProperties request
						EXPECT_HMICALL("UI.SetGlobalProperties", {})
						
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = ""})
						end)

					

						--mobile side: expect SetGlobalProperties response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", info = nil})
						:Timeout(iTimeout)
						
						EXPECT_NOTIFICATION("OnHashChange")	
						:Timeout(iTimeout)
					end

				--End Test case NegativeResponseCheck.2.2
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.2.3
				--Description: check negative response from both TTS and UI with invalid values(empty)

					--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-17, APPLINK-13276

					--Verification criteria: SDL forwards empty value of info to Mobile

					function Test:ResetGlobalProperties_TTS_and_UI_Response_Infor_empty()

						
						--mobile side: sending ResetGlobalProperties request
						local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
						{
							properties = 
							{
								"VRHELPTITLE",
								"MENUNAME",
								"MENUICON",
								"KEYBOARDPROPERTIES",
								"VRHELPITEMS",
								"HELPPROMPT",
								"TIMEOUTPROMPT"
							}
						})
						
						--hmi side: expect TTS.SetGlobalProperties request
						EXPECT_HMICALL("TTS.SetGlobalProperties", {})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending TTS.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = ""})
						end)

					

						--hmi side: expect UI.SetGlobalProperties request
						EXPECT_HMICALL("UI.SetGlobalProperties", {})
						
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = ""})
						end)

					

						--mobile side: expect SetGlobalProperties response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", info = nil})
						:Timeout(iTimeout)
						
						EXPECT_NOTIFICATION("OnHashChange")	
						:Timeout(iTimeout)
					end

				--End Test case NegativeResponseCheck.2.3
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.4
				--Description: check negative response from TTS with invalid values(invalid characters)

					--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-17, APPLINK-13276

					--Verification criteria: SDL forwards invalid characters value of info to Mobile

					function Test:ResetGlobalProperties_TTS_Response_Infor_invalid_characters_NewLine()

						
						--mobile side: sending ResetGlobalProperties request
						local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
						{
							properties = 
							{
								"VRHELPTITLE",
								"MENUNAME",
								"MENUICON",
								"KEYBOARDPROPERTIES",
								"VRHELPITEMS",
								"HELPPROMPT",
								"TIMEOUTPROMPT"
							}
						})
						
						--hmi side: expect TTS.SetGlobalProperties request
						EXPECT_HMICALL("TTS.SetGlobalProperties", {})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending TTS.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = "a\nb"})
						end)

					

						--hmi side: expect UI.SetGlobalProperties request
						EXPECT_HMICALL("UI.SetGlobalProperties", {}) 
						
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)

					

						--mobile side: expect SetGlobalProperties response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", info = nil})
						:Timeout(iTimeout)
						
						EXPECT_NOTIFICATION("OnHashChange")	
						:Timeout(iTimeout)
					end

				--End Test case NegativeResponseCheck.2.4
				-----------------------------------------------------------------------------------------

				
				--Begin Test case NegativeResponseCheck.2.5
				--Description: check negative response from UI with invalid values(invalid characters)

					--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-17, APPLINK-13276

					--Verification criteria: SDL forwards invalid characters value of info to Mobile

					function Test:ResetGlobalProperties_UI_Response_Infor_invalid_characters_NewLine()

						
						--mobile side: sending ResetGlobalProperties request
						local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
						{
							properties = 
							{
								"VRHELPTITLE",
								"MENUNAME",
								"MENUICON",
								"KEYBOARDPROPERTIES",
								"VRHELPITEMS",
								"HELPPROMPT",
								"TIMEOUTPROMPT"
							}
						})
						
						--hmi side: expect TTS.SetGlobalProperties request
						EXPECT_HMICALL("TTS.SetGlobalProperties", {})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending TTS.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)

					

						--hmi side: expect UI.SetGlobalProperties request
						EXPECT_HMICALL("UI.SetGlobalProperties", {})
						
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = "a\nb"})
						end)

					

						--mobile side: expect SetGlobalProperties response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", info = nil})
						:Timeout(iTimeout)
						
						EXPECT_NOTIFICATION("OnHashChange")	
						:Timeout(iTimeout)
					end

				--End Test case NegativeResponseCheck.2.5
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.2.6
				--Description: check negative response from both TTS and UI with invalid values(invalid characters)

					--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-17, APPLINK-13276

					--Verification criteria: SDL forwards invalid characters value of info to Mobile

					function Test:ResetGlobalProperties_TTS_and_UI_Response_Infor_invalid_characters_NewLine()

						
						--mobile side: sending ResetGlobalProperties request
						local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
						{
							properties = 
							{
								"VRHELPTITLE",
								"MENUNAME",
								"MENUICON",
								"KEYBOARDPROPERTIES",
								"VRHELPITEMS",
								"HELPPROMPT",
								"TIMEOUTPROMPT"
							}
						})
						
						--hmi side: expect TTS.SetGlobalProperties request
						EXPECT_HMICALL("TTS.SetGlobalProperties", {})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending TTS.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = "a\nc"})
						end)

					

						--hmi side: expect UI.SetGlobalProperties request
						EXPECT_HMICALL("UI.SetGlobalProperties", {})
						
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = "a\nb"})
						end)

					

						--mobile side: expect SetGlobalProperties response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", info = nil})
						:Timeout(iTimeout)
						
						EXPECT_NOTIFICATION("OnHashChange")	
						:Timeout(iTimeout)
					end

				--End Test case NegativeResponseCheck.2.6
				-----------------------------------------------------------------------------------------
				
			
			--End Test suit NegativeResponseCheck.2

			
			--Begin Test suit NegativeResponseCheck.3
			--Description: check negative response with wrong type
			
				--Begin Test case NegativeResponseCheck.3.1
				--Description: check info parameter is wrong type

					--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-17, APPLINK-13276

					--Verification criteria: ResetGlobalProperties responses contains info parameter contains wrong data type

					function Test:ResetGlobalProperties_TTS_Response_Infor_wrongType()
						
						--mobile side: sending ResetGlobalProperties request
						local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
						{
							properties = 
							{
								"VRHELPTITLE",
								"MENUNAME",
								"MENUICON",
								"KEYBOARDPROPERTIES",
								"VRHELPITEMS",
								"HELPPROMPT",
								"TIMEOUTPROMPT"
							}
						})
						--hmi side: expect TTS.SetGlobalProperties request
						EXPECT_HMICALL("TTS.SetGlobalProperties", {})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending TTS.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = 123})
						end)

					

						--hmi side: expect UI.SetGlobalProperties request
						EXPECT_HMICALL("UI.SetGlobalProperties", {})
						
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)

					

						--mobile side: expect SetGlobalProperties response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", info = nil})
						EXPECT_NOTIFICATION("OnHashChange")			
					end

				--End Test case NegativeResponseCheck.3.1
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.3.2
				--Description: check info parameter is wrong type

					--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-17, APPLINK-13276

					--Verification criteria: ResetGlobalProperties responses contains info parameter contains wrong data type

					function Test:ResetGlobalProperties_UI_Response_Infor_wrongType()
						
						--mobile side: sending ResetGlobalProperties request
						local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
						{
							properties = 
							{
								"VRHELPTITLE",
								"MENUNAME",
								"MENUICON",
								"KEYBOARDPROPERTIES",
								"VRHELPITEMS",
								"HELPPROMPT",
								"TIMEOUTPROMPT"
							}
						})
						--hmi side: expect TTS.SetGlobalProperties request
						EXPECT_HMICALL("TTS.SetGlobalProperties", {})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending TTS.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)

					

						--hmi side: expect UI.SetGlobalProperties request
						EXPECT_HMICALL("UI.SetGlobalProperties", {})
						
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = 123})
						end)

					

						--mobile side: expect SetGlobalProperties response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", info = nil})
						EXPECT_NOTIFICATION("OnHashChange")			
					end

				--End Test case NegativeResponseCheck.3.2
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.3.3
				--Description: check info parameter is wrong type

					--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-17, APPLINK-13276

					--Verification criteria: ResetGlobalProperties responses contains info parameter contains wrong data type

					function Test:ResetGlobalProperties_TTS_And_UI_Response_Infor_wrongType()
						
						--mobile side: sending ResetGlobalProperties request
						local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
						{
							properties = 
							{
								"VRHELPTITLE",
								"MENUNAME",
								"MENUICON",
								"KEYBOARDPROPERTIES",
								"VRHELPITEMS",
								"HELPPROMPT",
								"TIMEOUTPROMPT"
							}
						})
						--hmi side: expect TTS.SetGlobalProperties request
						EXPECT_HMICALL("TTS.SetGlobalProperties", {})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending TTS.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = 123})
						end)

					

						--hmi side: expect UI.SetGlobalProperties request
						EXPECT_HMICALL("UI.SetGlobalProperties", {})
						
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = 123})
						end)

					

						--mobile side: expect SetGlobalProperties response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", info = nil})
						EXPECT_NOTIFICATION("OnHashChange")			
					end

				--End Test case NegativeResponseCheck.3.3
	]]
				-----------------------------------------------------------------------------------------
				
			--End Test suit NegativeResponseCheck.3


			--Begin Test suit NegativeResponseCheck.4
			--Description: check negative response with invalid json
			
--ToDo: Only run this cases when APPLINK-13418 is fixed			
--[[
				--Begin Test case NegativeResponseCheck.4.1
				--Description: check negative response with invalid json from TTS

					--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-395

					--Verification criteria:  The response with wrong JSON syntax is sent, the response comes to Mobile with INVALID_DATA result code.

					function Test:ResetGlobalProperties_TTS_Response_Invalid_JSON()
						
						--mobile side: sending ResetGlobalProperties request
						local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
						{
							properties = 
							{
								"VRHELPTITLE",
								"MENUNAME",
								"MENUICON",
								"KEYBOARDPROPERTIES",
								"VRHELPITEMS",
								"HELPPROMPT",
								"TIMEOUTPROMPT"
							}
						})
						--hmi side: expect TTS.SetGlobalProperties request
						EXPECT_HMICALL("TTS.SetGlobalProperties", {})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending TTS.SetGlobalProperties response
							--self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
							--change ":" by ";" after "code"
						  self.hmiConnection:Send('{"jsonrpc":"2.0","id":'..tostring(data.id)..',"result":{"code":0,"method":"TTS.SetGlobalProperties"}}')					
							--xxxxxxxxx self.hmiConnection:Send('{"jsonrpc":"2.0","id":'..tostring(data.id)..',"result":{"code";0,"method":"TTS.SetGlobalProperties"}}')
						end)

					

						--hmi side: expect UI.SetGlobalProperties request
						EXPECT_HMICALL("UI.SetGlobalProperties", {})
						
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)

					

						--mobile side: expect SetGlobalProperties response		
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
						:Timeout(iTimeout)
						
						EXPECT_NOTIFICATION("OnHashChange")			
						:Times(0)
						:Timeout(11000)
						
					end

				--End Test case NegativeResponseCheck.4.1
				-----------------------------------------------------------------------------------------			
			
				--Begin Test case NegativeResponseCheck.4.2
				--Description: check negative response with invalid json from UI

					--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-395

					--Verification criteria:  The response with wrong JSON syntax is sent, the response comes to Mobile with INVALID_DATA result code.

					function Test:ResetGlobalProperties_UI_Response_Invalid_JSON()
						
						--mobile side: sending ResetGlobalProperties request
						local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
						{
							properties = 
							{
								"VRHELPTITLE",
								"MENUNAME",
								"MENUICON",
								"KEYBOARDPROPERTIES",
								"VRHELPITEMS",
								"HELPPROMPT",
								"TIMEOUTPROMPT"
							}
						})
						--hmi side: expect TTS.SetGlobalProperties request
						EXPECT_HMICALL("TTS.SetGlobalProperties", {})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending TTS.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)

					

						--hmi side: expect UI.SetGlobalProperties request
						EXPECT_HMICALL("UI.SetGlobalProperties", {})
						
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							--self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
							--change ":" by ";" after "code"
						  --self.hmiConnection:Send('{"jsonrpc":"2.0","id":'..tostring(data.id)..',"result":{"code":0,"method":"UI.SetGlobalProperties"}}')					
							self.hmiConnection:Send('{"jsonrpc":"2.0","id":'..tostring(data.id)..',"result":{"code";0,"method":"UI.SetGlobalProperties"}}')							
						end)

					

						--mobile side: expect SetGlobalProperties response		
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
						:Timeout(iTimeout)
						
						EXPECT_NOTIFICATION("OnHashChange")			
						:Times(0)
						:Timeout(11000)
						
					end

				--End Test case NegativeResponseCheck.4.2
				-----------------------------------------------------------------------------------------			
						

						
				--Begin Test case NegativeResponseCheck.4.3
				--Description: check negative response with invalid json from both TTS and UI

					--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-395

					--Verification criteria:  The response with wrong JSON syntax is sent, the response comes to Mobile with INVALID_DATA result code.

					function Test:ResetGlobalProperties_TTS_and_UI_Response_Invalid_JSON()
						
						--mobile side: sending ResetGlobalProperties request
						local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
						{
							properties = 
							{
								"VRHELPTITLE",
								"MENUNAME",
								"MENUICON",
								"KEYBOARDPROPERTIES",
								"VRHELPITEMS",
								"HELPPROMPT",
								"TIMEOUTPROMPT"
							}
						})
						--hmi side: expect TTS.SetGlobalProperties request
						EXPECT_HMICALL("TTS.SetGlobalProperties", {})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending TTS.SetGlobalProperties response
							--self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
							--change ":" by ";" after "code"
						  --self.hmiConnection:Send('{"jsonrpc":"2.0","id":'..tostring(data.id)..',"result":{"code":0,"method":"TTS.SetGlobalProperties"}}')					
							self.hmiConnection:Send('{"jsonrpc":"2.0","id":'..tostring(data.id)..',"result":{"code";0,"method":"TTS.SetGlobalProperties"}}')
						end)

					

						--hmi side: expect UI.SetGlobalProperties request
						EXPECT_HMICALL("UI.SetGlobalProperties", {})
						
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							--self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
							--change ":" by ";" after "code"
						  --self.hmiConnection:Send('{"jsonrpc":"2.0","id":'..tostring(data.id)..',"result":{"code":0,"method":"UI.SetGlobalProperties"}}')					
							self.hmiConnection:Send('{"jsonrpc":"2.0","id":'..tostring(data.id)..',"result":{"code";0,"method":"UI.SetGlobalProperties"}}')							
						end)

					

						--mobile side: expect SetGlobalProperties response		
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
						:Timeout(iTimeout)
						
						EXPECT_NOTIFICATION("OnHashChange")			
						:Times(0)
						:Timeout(11000)
						
					end

				--End Test case NegativeResponseCheck.4.3
				-----------------------------------------------------------------------------------------			
	]]--					
			--End Test suit NegativeResponseCheck.4	
			
			-----------------------------------------------------------------------------------------
			
--[[TODO: Update according to  APPLINK-14765		
			--Begin Test case NegativeResponseCheck.5
			--Description: Check processing response with outbound values

				--Requirement id in JAMA:
					--SDLAQ-CRS-17
				--Verification criteria:
					-- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
				
				--Begin Test case NegativeResponseCheck.5.1
				--Description: Check UI response with nonexistent resultCode 
					function Test: ResetGlobalProperties_UIResponseResultCodeNotExist()
						--mobile side: sending ResetGlobalProperties request
						local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
						{
							properties = 
							{
								"TTSHELPTITLE",
								"MENUNAME",
								"MENUICON",
								"KEYBOARDPROPERTIES",
								"TTSHELPITEMS",
								"HELPPROMPT",
								"TIMEOUTPROMPT"
							}
						})
						--hmi side: expect TTS.SetGlobalProperties request
						EXPECT_HMICALL("TTS.SetGlobalProperties",
						{
							helpPrompt = 
							{
								{
									type = "TEXT",
									text = textPromtValue[1]
								},
								{
									type = "TEXT",
									text = textPromtValue[2]
								}
							},
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
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending TTS.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
					

						--hmi side: expect UI.SetGlobalProperties request
						EXPECT_HMICALL("UI.SetGlobalProperties",
						{
							menuTitle = title_to_check,
							menuIcon = {
											imageType = "DYNAMIC",
											value = icon_to_check
										},
							vrHelpTitle = "Test Application",
							keyboardProperties = 
							{
								keyboardLayout = "QWERTY",
								autoCompleteText = "",
								language = "EN-US"
							},
							vrHelp = nil
						})
						
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "ANY", {})
						end)								
						
						--mobile side: expect ResetGlobalProperties response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)		
					end
				--End Test case NegativeResponseCheck.5.1
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.5.2
				--Description: Check TTS response with nonexistent resultCode 
					function Test: ResetGlobalProperties_TTSResponseResultCodeNotExist()
						--mobile side: sending ResetGlobalProperties request
						local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
						{
							properties = 
							{
								"TTSHELPTITLE",
								"MENUNAME",
								"MENUICON",
								"KEYBOARDPROPERTIES",
								"TTSHELPITEMS",
								"HELPPROMPT",
								"TIMEOUTPROMPT"
							}
						})
						--hmi side: expect TTS.SetGlobalProperties request
						EXPECT_HMICALL("TTS.SetGlobalProperties",
						{
							helpPrompt = 
							{
								{
									type = "TEXT",
									text = textPromtValue[1]
								},
								{
									type = "TEXT",
									text = textPromtValue[2]
								}
							},
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
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending TTS.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "ANY", {})
						end)
					

						--hmi side: expect UI.SetGlobalProperties request
						EXPECT_HMICALL("UI.SetGlobalProperties",
						{
							menuTitle = title_to_check,
							menuIcon = {
											imageType = "DYNAMIC",
											value = icon_to_check
										},
							vrHelpTitle = "Test Application",
							keyboardProperties = 
							{
								keyboardLayout = "QWERTY",
								autoCompleteText = "",
								language = "EN-US"
							},
							vrHelp = nil
						})
						
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)								
						
						--mobile side: expect ResetGlobalProperties response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })	
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)	
					end
				--End Test case NegativeResponseCheck.5.2
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.5.3
				--Description: Check UI TTS response with nonexistent resultCode 
					function Test: ResetGlobalProperties_UITTSResponseResultCodeNotExist()
						--mobile side: sending ResetGlobalProperties request
						local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
						{
							properties = 
							{
								"TTSHELPTITLE",
								"MENUNAME",
								"MENUICON",
								"KEYBOARDPROPERTIES",
								"TTSHELPITEMS",
								"HELPPROMPT",
								"TIMEOUTPROMPT"
							}
						})
						--hmi side: expect TTS.SetGlobalProperties request
						EXPECT_HMICALL("TTS.SetGlobalProperties",
						{
							helpPrompt = 
							{
								{
									type = "TEXT",
									text = textPromtValue[1]
								},
								{
									type = "TEXT",
									text = textPromtValue[2]
								}
							},
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
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending TTS.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "ANY", {})
						end)
					

						--hmi side: expect UI.SetGlobalProperties request
						EXPECT_HMICALL("UI.SetGlobalProperties",
						{
							menuTitle = title_to_check,
							menuIcon = {
											imageType = "DYNAMIC",
											value = icon_to_check
										},
							vrHelpTitle = "Test Application",
							keyboardProperties = 
							{
								keyboardLayout = "QWERTY",
								autoCompleteText = "",
								language = "EN-US"
							},
							vrHelp = nil
						})
						
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "ANY", {})
						end)								
						
						--mobile side: expect ResetGlobalProperties response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })	
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)	
					end
				--End Test case NegativeResponseCheck.5.3
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.5.4
				--Description: Check UI response with empty string in method
					function Test: ResetGlobalProperties_UIResponseMethodOutLowerBound()
						--mobile side: sending ResetGlobalProperties request
						local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
						{
							properties = 
							{
								"TTSHELPTITLE",
								"MENUNAME",
								"MENUICON",
								"KEYBOARDPROPERTIES",
								"TTSHELPITEMS",
								"HELPPROMPT",
								"TIMEOUTPROMPT"
							}
						})
						--hmi side: expect TTS.SetGlobalProperties request
						EXPECT_HMICALL("TTS.SetGlobalProperties",
						{
							helpPrompt = 
							{
								{
									type = "TEXT",
									text = textPromtValue[1]
								},
								{
									type = "TEXT",
									text = textPromtValue[2]
								}
							},
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
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending TTS.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
					

						--hmi side: expect UI.SetGlobalProperties request
						EXPECT_HMICALL("UI.SetGlobalProperties",
						{
							menuTitle = title_to_check,
							menuIcon = {
											imageType = "DYNAMIC",
											value = icon_to_check
										},
							vrHelpTitle = "Test Application",
							keyboardProperties = 
							{
								keyboardLayout = "QWERTY",
								autoCompleteText = "",
								language = "EN-US"
							},
							vrHelp = nil
						})
						
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, "", "SUCCESS", {})
						end)	
						
						--mobile side: expect ResetGlobalProperties response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
						:Timeout(12000)
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
						:Timeout(12000)
					end
				--End Test case NegativeResponseCheck.5.4
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.5.5
				--Description: Check TTS response with empty string in method
					function Test: ResetGlobalProperties_TTSResponseMethodOutLowerBound()
						--mobile side: sending ResetGlobalProperties request
						local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
						{
							properties = 
							{
								"TTSHELPTITLE",
								"MENUNAME",
								"MENUICON",
								"KEYBOARDPROPERTIES",
								"TTSHELPITEMS",
								"HELPPROMPT",
								"TIMEOUTPROMPT"
							}
						})
						--hmi side: expect TTS.SetGlobalProperties request
						EXPECT_HMICALL("TTS.SetGlobalProperties",
						{
							helpPrompt = 
							{
								{
									type = "TEXT",
									text = textPromtValue[1]
								},
								{
									type = "TEXT",
									text = textPromtValue[2]
								}
							},
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
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending TTS.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, "", "SUCCESS", {})
						end)
					

						--hmi side: expect UI.SetGlobalProperties request
						EXPECT_HMICALL("UI.SetGlobalProperties",
						{
							menuTitle = title_to_check,
							menuIcon = {
											imageType = "DYNAMIC",
											value = icon_to_check
										},
							vrHelpTitle = "Test Application",
							keyboardProperties = 
							{
								keyboardLayout = "QWERTY",
								autoCompleteText = "",
								language = "EN-US"
							},
							vrHelp = nil
						})
						
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)								
						
						--mobile side: expect ResetGlobalProperties response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
						:Timeout(12000)
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
						:Timeout(12000)
					end
				--End Test case NegativeResponseCheck.5.5
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.5.6
				--Description: Check UI TTS response with empty string in method
					function Test: ResetGlobalProperties_UITTSResponseMethodOutLowerBound()
						--mobile side: sending ResetGlobalProperties request
						local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
						{
							properties = 
							{
								"TTSHELPTITLE",
								"MENUNAME",
								"MENUICON",
								"KEYBOARDPROPERTIES",
								"TTSHELPITEMS",
								"HELPPROMPT",
								"TIMEOUTPROMPT"
							}
						})
						--hmi side: expect TTS.SetGlobalProperties request
						EXPECT_HMICALL("TTS.SetGlobalProperties",
						{
							helpPrompt = 
							{
								{
									type = "TEXT",
									text = textPromtValue[1]
								},
								{
									type = "TEXT",
									text = textPromtValue[2]
								}
							},
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
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending TTS.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, "", "SUCCESS", {})
						end)
					

						--hmi side: expect UI.SetGlobalProperties request
						EXPECT_HMICALL("UI.SetGlobalProperties",
						{
							menuTitle = title_to_check,
							menuIcon = {
											imageType = "DYNAMIC",
											value = icon_to_check
										},
							vrHelpTitle = "Test Application",
							keyboardProperties = 
							{
								keyboardLayout = "QWERTY",
								autoCompleteText = "",
								language = "EN-US"
							},
							vrHelp = nil
						})
						
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, "", "SUCCESS", {})
						end)								
						
						--mobile side: expect ResetGlobalProperties response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
						:Timeout(12000)
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
						:Timeout(12000)
					end
				--End Test case NegativeResponseCheck.5.6
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.5.7
				--Description: Check UI response with empty string in resultCode
					function Test: ResetGlobalProperties_UIResponseResultCodeOutLowerBound()
						--mobile side: sending ResetGlobalProperties request
						local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
						{
							properties = 
							{
								"TTSHELPTITLE",
								"MENUNAME",
								"MENUICON",
								"KEYBOARDPROPERTIES",
								"TTSHELPITEMS",
								"HELPPROMPT",
								"TIMEOUTPROMPT"
							}
						})
						--hmi side: expect TTS.SetGlobalProperties request
						EXPECT_HMICALL("TTS.SetGlobalProperties",
						{
							helpPrompt = 
							{
								{
									type = "TEXT",
									text = textPromtValue[1]
								},
								{
									type = "TEXT",
									text = textPromtValue[2]
								}
							},
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
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending TTS.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
					

						--hmi side: expect UI.SetGlobalProperties request
						EXPECT_HMICALL("UI.SetGlobalProperties",
						{
							menuTitle = title_to_check,
							menuIcon = {
											imageType = "DYNAMIC",
											value = icon_to_check
										},
							vrHelpTitle = "Test Application",
							keyboardProperties = 
							{
								keyboardLayout = "QWERTY",
								autoCompleteText = "",
								language = "EN-US"
							},
							vrHelp = nil
						})
						
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "", {})
						end)								
						
						--mobile side: expect ResetGlobalProperties response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeResponseCheck.5.7
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.5.8
				--Description: Check UI TTS response with empty string in resultCode
					function Test: ResetGlobalProperties_UITTSResponseResultCodeOutLowerBound()
						--mobile side: sending ResetGlobalProperties request
						local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
						{
							properties = 
							{
								"TTSHELPTITLE",
								"MENUNAME",
								"MENUICON",
								"KEYBOARDPROPERTIES",
								"TTSHELPITEMS",
								"HELPPROMPT",
								"TIMEOUTPROMPT"
							}
						})
						--hmi side: expect TTS.SetGlobalProperties request
						EXPECT_HMICALL("TTS.SetGlobalProperties",
						{
							helpPrompt = 
							{
								{
									type = "TEXT",
									text = textPromtValue[1]
								},
								{
									type = "TEXT",
									text = textPromtValue[2]
								}
							},
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
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending TTS.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "", {})
						end)
					

						--hmi side: expect UI.SetGlobalProperties request
						EXPECT_HMICALL("UI.SetGlobalProperties",
						{
							menuTitle = title_to_check,
							menuIcon = {
											imageType = "DYNAMIC",
											value = icon_to_check
										},
							vrHelpTitle = "Test Application",
							keyboardProperties = 
							{
								keyboardLayout = "QWERTY",
								autoCompleteText = "",
								language = "EN-US"
							},
							vrHelp = nil
						})
						
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)								
						
						--mobile side: expect ResetGlobalProperties response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeResponseCheck.5.8			
			
				-----------------------------------------------------------------------------------------

				--Begin NegativeResponseCheck.5.9
				--Description: Check UI response without all parameters				
					function Test: ResetGlobalProperties_UIResponseMissingAllPArameters()					
						--mobile side: sending ResetGlobalProperties request
						local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
						{
							properties = 
							{
								"TTSHELPTITLE",
								"MENUNAME",
								"MENUICON",
								"KEYBOARDPROPERTIES",
								"TTSHELPITEMS",
								"HELPPROMPT",
								"TIMEOUTPROMPT"
							}
						})
						--hmi side: expect TTS.SetGlobalProperties request
						EXPECT_HMICALL("TTS.SetGlobalProperties",
						{
							helpPrompt = 
							{
								{
									type = "TEXT",
									text = textPromtValue[1]
								},
								{
									type = "TEXT",
									text = textPromtValue[2]
								}
							},
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
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending TTS.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
					

						--hmi side: expect UI.SetGlobalProperties request
						EXPECT_HMICALL("UI.SetGlobalProperties",
						{
							menuTitle = title_to_check,
							menuIcon = {
											imageType = "DYNAMIC",
											value = icon_to_check
										},
							vrHelpTitle = "Test Application",
							keyboardProperties = 
							{
								keyboardLayout = "QWERTY",
								autoCompleteText = "",
								language = "EN-US"
							},
							vrHelp = nil
						})
						
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							self.hmiConnection:Send({})
						end)								
						
						--mobile side: expect ResetGlobalProperties response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })	
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)	
					end
				--End NegativeResponseCheck.5.9
				
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.5.10
				--Description: Check TTS response without all parameters				
					function Test: ResetGlobalProperties_TTSResponseMissingAllPArameters()					
						--mobile side: sending ResetGlobalProperties request
						local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
						{
							properties = 
							{
								"TTSHELPTITLE",
								"MENUNAME",
								"MENUICON",
								"KEYBOARDPROPERTIES",
								"TTSHELPITEMS",
								"HELPPROMPT",
								"TIMEOUTPROMPT"
							}
						})
						--hmi side: expect TTS.SetGlobalProperties request
						EXPECT_HMICALL("TTS.SetGlobalProperties",
						{
							helpPrompt = 
							{
								{
									type = "TEXT",
									text = textPromtValue[1]
								},
								{
									type = "TEXT",
									text = textPromtValue[2]
								}
							},
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
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending TTS.SetGlobalProperties response
							self.hmiConnection:Send({})
						end)
					

						--hmi side: expect UI.SetGlobalProperties request
						EXPECT_HMICALL("UI.SetGlobalProperties",
						{
							menuTitle = title_to_check,
							menuIcon = {
											imageType = "DYNAMIC",
											value = icon_to_check
										},
							vrHelpTitle = "Test Application",
							keyboardProperties = 
							{
								keyboardLayout = "QWERTY",
								autoCompleteText = "",
								language = "EN-US"
							},
							vrHelp = nil
						})
						
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)								
						
						--mobile side: expect ResetGlobalProperties response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })	
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)	
					end
				--End NegativeResponseCheck.5.10
				
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.5.11
				--Description: Check UI TTS response without all parameters				
					function Test: ResetGlobalProperties_UITTSResponseMissingAllPArameters()					
						--mobile side: sending ResetGlobalProperties request
						local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
						{
							properties = 
							{
								"TTSHELPTITLE",
								"MENUNAME",
								"MENUICON",
								"KEYBOARDPROPERTIES",
								"TTSHELPITEMS",
								"HELPPROMPT",
								"TIMEOUTPROMPT"
							}
						})
						--hmi side: expect TTS.SetGlobalProperties request
						EXPECT_HMICALL("TTS.SetGlobalProperties",
						{
							helpPrompt = 
							{
								{
									type = "TEXT",
									text = textPromtValue[1]
								},
								{
									type = "TEXT",
									text = textPromtValue[2]
								}
							},
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
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending TTS.SetGlobalProperties response
							self.hmiConnection:Send({})
						end)
					

						--hmi side: expect UI.SetGlobalProperties request
						EXPECT_HMICALL("UI.SetGlobalProperties",
						{
							menuTitle = title_to_check,
							menuIcon = {
											imageType = "DYNAMIC",
											value = icon_to_check
										},
							vrHelpTitle = "Test Application",
							keyboardProperties = 
							{
								keyboardLayout = "QWERTY",
								autoCompleteText = "",
								language = "EN-US"
							},
							vrHelp = nil
						})
						
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							self.hmiConnection:Send({})
						end)								
						
						--mobile side: expect ResetGlobalProperties response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)		
					end
				--End NegativeResponseCheck.5.11
				
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.5.11
				--Description: Check UI response without method parameter			
					function Test: ResetGlobalProperties_UIResponseMethodMissing()					
						--mobile side: sending ResetGlobalProperties request
						local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
						{
							properties = 
							{
								"TTSHELPTITLE",
								"MENUNAME",
								"MENUICON",
								"KEYBOARDPROPERTIES",
								"TTSHELPITEMS",
								"HELPPROMPT",
								"TIMEOUTPROMPT"
							}
						})
						--hmi side: expect TTS.SetGlobalProperties request
						EXPECT_HMICALL("TTS.SetGlobalProperties",
						{
							helpPrompt = 
							{
								{
									type = "TEXT",
									text = textPromtValue[1]
								},
								{
									type = "TEXT",
									text = textPromtValue[2]
								}
							},
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
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending TTS.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
					

						--hmi side: expect UI.SetGlobalProperties request
						EXPECT_HMICALL("UI.SetGlobalProperties",
						{
							menuTitle = title_to_check,
							menuIcon = {
											imageType = "DYNAMIC",
											value = icon_to_check
										},
							vrHelpTitle = "Test Application",
							keyboardProperties = 
							{
								keyboardLayout = "QWERTY",
								autoCompleteText = "",
								language = "EN-US"
							},
							vrHelp = nil
						})
						
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0}}')
						end)	
						
						--mobile side: expect ResetGlobalProperties response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
						:Timeout(12000)
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
						:Timeout(12000)		
					end
				--End NegativeResponseCheck.5.11
				
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.5.12
				--Description: Check TTS response without method parameter			
					function Test: ResetGlobalProperties_TTSResponseMethodMissing()					
						--mobile side: sending ResetGlobalProperties request
						local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
						{
							properties = 
							{
								"TTSHELPTITLE",
								"MENUNAME",
								"MENUICON",
								"KEYBOARDPROPERTIES",
								"TTSHELPITEMS",
								"HELPPROMPT",
								"TIMEOUTPROMPT"
							}
						})
						--hmi side: expect TTS.SetGlobalProperties request
						EXPECT_HMICALL("TTS.SetGlobalProperties",
						{
							helpPrompt = 
							{
								{
									type = "TEXT",
									text = textPromtValue[1]
								},
								{
									type = "TEXT",
									text = textPromtValue[2]
								}
							},
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
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending TTS.SetGlobalProperties response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0}}')
						end)
					

						--hmi side: expect UI.SetGlobalProperties request
						EXPECT_HMICALL("UI.SetGlobalProperties",
						{
							menuTitle = title_to_check,
							menuIcon = {
											imageType = "DYNAMIC",
											value = icon_to_check
										},
							vrHelpTitle = "Test Application",
							keyboardProperties = 
							{
								keyboardLayout = "QWERTY",
								autoCompleteText = "",
								language = "EN-US"
							},
							vrHelp = nil
						})
						
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)			
							
						--mobile side: expect ResetGlobalProperties response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
						:Timeout(12000)		
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
						:Timeout(12000)
					end
				--End NegativeResponseCheck.5.12
				
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.5.13
				--Description: Check UI TTS response without method parameter			
					function Test: ResetGlobalProperties_UITTSResponseMethodMissing()					
						--mobile side: sending ResetGlobalProperties request
						local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
						{
							properties = 
							{
								"TTSHELPTITLE",
								"MENUNAME",
								"MENUICON",
								"KEYBOARDPROPERTIES",
								"TTSHELPITEMS",
								"HELPPROMPT",
								"TIMEOUTPROMPT"
							}
						})
						--hmi side: expect TTS.SetGlobalProperties request
						EXPECT_HMICALL("TTS.SetGlobalProperties",
						{
							helpPrompt = 
							{
								{
									type = "TEXT",
									text = textPromtValue[1]
								},
								{
									type = "TEXT",
									text = textPromtValue[2]
								}
							},
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
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending TTS.SetGlobalProperties response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0}}')
						end)
					

						--hmi side: expect UI.SetGlobalProperties request
						EXPECT_HMICALL("UI.SetGlobalProperties",
						{
							menuTitle = title_to_check,
							menuIcon = {
											imageType = "DYNAMIC",
											value = icon_to_check
										},
							vrHelpTitle = "Test Application",
							keyboardProperties = 
							{
								keyboardLayout = "QWERTY",
								autoCompleteText = "",
								language = "EN-US"
							},
							vrHelp = nil
						})
						
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0}}')
						end)			
							
						--mobile side: expect ResetGlobalProperties response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
						:Timeout(12000)		
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
						:Timeout(12000)
					end
				--End NegativeResponseCheck.5.13
				
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.5.14
				--Description: Check UI response without resultCode parameter
					function Test: ResetGlobalProperties_UIResponseResultCodeMissing()					
						--mobile side: sending ResetGlobalProperties request
						local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
						{
							properties = 
							{
								"TTSHELPTITLE",
								"MENUNAME",
								"MENUICON",
								"KEYBOARDPROPERTIES",
								"TTSHELPITEMS",
								"HELPPROMPT",
								"TIMEOUTPROMPT"
							}
						})
						--hmi side: expect TTS.SetGlobalProperties request
						EXPECT_HMICALL("TTS.SetGlobalProperties",
						{
							helpPrompt = 
							{
								{
									type = "TEXT",
									text = textPromtValue[1]
								},
								{
									type = "TEXT",
									text = textPromtValue[2]
								}
							},
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
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending TTS.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
					

						--hmi side: expect UI.SetGlobalProperties request
						EXPECT_HMICALL("UI.SetGlobalProperties",
						{
							menuTitle = title_to_check,
							menuIcon = {
											imageType = "DYNAMIC",
											value = icon_to_check
										},
							vrHelpTitle = "Test Application",
							keyboardProperties = 
							{
								keyboardLayout = "QWERTY",
								autoCompleteText = "",
								language = "EN-US"
							},
							vrHelp = nil
						})
						
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.ResetGlobalProperties"}}')
						end)								
						
						--mobile side: expect ResetGlobalProperties response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })	
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)					
					end
				--End NegativeResponseCheck.5.14
				
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.5.15
				--Description: Check TTS response without resultCode parameter
					function Test: ResetGlobalProperties_TTSResponseResultCodeMissing()					
						--mobile side: sending ResetGlobalProperties request
						local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
						{
							properties = 
							{
								"TTSHELPTITLE",
								"MENUNAME",
								"MENUICON",
								"KEYBOARDPROPERTIES",
								"TTSHELPITEMS",
								"HELPPROMPT",
								"TIMEOUTPROMPT"
							}
						})
						--hmi side: expect TTS.SetGlobalProperties request
						EXPECT_HMICALL("TTS.SetGlobalProperties",
						{
							helpPrompt = 
							{
								{
									type = "TEXT",
									text = textPromtValue[1]
								},
								{
									type = "TEXT",
									text = textPromtValue[2]
								}
							},
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
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending TTS.SetGlobalProperties response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"TTS.ResetGlobalProperties"}}')
						end)
					

						--hmi side: expect UI.SetGlobalProperties request
						EXPECT_HMICALL("UI.SetGlobalProperties",
						{
							menuTitle = title_to_check,
							menuIcon = {
											imageType = "DYNAMIC",
											value = icon_to_check
										},
							vrHelpTitle = "Test Application",
							keyboardProperties = 
							{
								keyboardLayout = "QWERTY",
								autoCompleteText = "",
								language = "EN-US"
							},
							vrHelp = nil
						})
						
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)								
						
						--mobile side: expect ResetGlobalProperties response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })	
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)				
					end
				--End NegativeResponseCheck.5.15
				
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.5.16
				--Description: Check UI TTS response without resultCode parameter
					function Test: ResetGlobalProperties_UITTSResponseResultCodeMissing()					
						--mobile side: sending ResetGlobalProperties request
						local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
						{
							properties = 
							{
								"TTSHELPTITLE",
								"MENUNAME",
								"MENUICON",
								"KEYBOARDPROPERTIES",
								"TTSHELPITEMS",
								"HELPPROMPT",
								"TIMEOUTPROMPT"
							}
						})
						--hmi side: expect TTS.SetGlobalProperties request
						EXPECT_HMICALL("TTS.SetGlobalProperties",
						{
							helpPrompt = 
							{
								{
									type = "TEXT",
									text = textPromtValue[1]
								},
								{
									type = "TEXT",
									text = textPromtValue[2]
								}
							},
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
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending TTS.SetGlobalProperties response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"TTS.ResetGlobalProperties"}}')
						end)
					

						--hmi side: expect UI.SetGlobalProperties request
						EXPECT_HMICALL("UI.SetGlobalProperties",
						{
							menuTitle = title_to_check,
							menuIcon = {
											imageType = "DYNAMIC",
											value = icon_to_check
										},
							vrHelpTitle = "Test Application",
							keyboardProperties = 
							{
								keyboardLayout = "QWERTY",
								autoCompleteText = "",
								language = "EN-US"
							},
							vrHelp = nil
						})
						
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.ResetGlobalProperties"}}')
						end)								
						
						--mobile side: expect ResetGlobalProperties response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)					
					end
				--End NegativeResponseCheck.5.16
				
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.5.17
				--Description: Check UI response without mandatory parameter
					function Test: ResetGlobalProperties_UIResponseAllMandatoryMissing()					
						--mobile side: sending ResetGlobalProperties request
						local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
						{
							properties = 
							{
								"TTSHELPTITLE",
								"MENUNAME",
								"MENUICON",
								"KEYBOARDPROPERTIES",
								"TTSHELPITEMS",
								"HELPPROMPT",
								"TIMEOUTPROMPT"
							}
						})
						--hmi side: expect TTS.SetGlobalProperties request
						EXPECT_HMICALL("TTS.SetGlobalProperties",
						{
							helpPrompt = 
							{
								{
									type = "TEXT",
									text = textPromtValue[1]
								},
								{
									type = "TEXT",
									text = textPromtValue[2]
								}
							},
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
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending TTS.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
					

						--hmi side: expect UI.SetGlobalProperties request
						EXPECT_HMICALL("UI.SetGlobalProperties",
						{
							menuTitle = title_to_check,
							menuIcon = {
											imageType = "DYNAMIC",
											value = icon_to_check
										},
							vrHelpTitle = "Test Application",
							keyboardProperties = 
							{
								keyboardLayout = "QWERTY",
								autoCompleteText = "",
								language = "EN-US"
							},
							vrHelp = nil
						})
						
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{}}')
						end)								
						
						--mobile side: expect ResetGlobalProperties response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End NegativeResponseCheck.5.17
				
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.5.18
				--Description: Check TTS response without mandatory parameter
					function Test: ResetGlobalProperties_TTSResponseAllMandatoryMissing()					
						--mobile side: sending ResetGlobalProperties request
						local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
						{
							properties = 
							{
								"TTSHELPTITLE",
								"MENUNAME",
								"MENUICON",
								"KEYBOARDPROPERTIES",
								"TTSHELPITEMS",
								"HELPPROMPT",
								"TIMEOUTPROMPT"
							}
						})
						--hmi side: expect TTS.SetGlobalProperties request
						EXPECT_HMICALL("TTS.SetGlobalProperties",
						{
							helpPrompt = 
							{
								{
									type = "TEXT",
									text = textPromtValue[1]
								},
								{
									type = "TEXT",
									text = textPromtValue[2]
								}
							},
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
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending TTS.SetGlobalProperties response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{}}')
						end)
					

						--hmi side: expect UI.SetGlobalProperties request
						EXPECT_HMICALL("UI.SetGlobalProperties",
						{
							menuTitle = title_to_check,
							menuIcon = {
											imageType = "DYNAMIC",
											value = icon_to_check
										},
							vrHelpTitle = "Test Application",
							keyboardProperties = 
							{
								keyboardLayout = "QWERTY",
								autoCompleteText = "",
								language = "EN-US"
							},
							vrHelp = nil
						})
						
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)								
						
						--mobile side: expect ResetGlobalProperties response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End NegativeResponseCheck.5.18				
				
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.5.19
				--Description: Check UI TTS response without mandatory parameter
					function Test: ResetGlobalProperties_UITTSResponseAllMandatoryMissing()					
						--mobile side: sending ResetGlobalProperties request
						local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
						{
							properties = 
							{
								"TTSHELPTITLE",
								"MENUNAME",
								"MENUICON",
								"KEYBOARDPROPERTIES",
								"TTSHELPITEMS",
								"HELPPROMPT",
								"TIMEOUTPROMPT"
							}
						})
						--hmi side: expect TTS.SetGlobalProperties request
						EXPECT_HMICALL("TTS.SetGlobalProperties",
						{
							helpPrompt = 
							{
								{
									type = "TEXT",
									text = textPromtValue[1]
								},
								{
									type = "TEXT",
									text = textPromtValue[2]
								}
							},
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
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending TTS.SetGlobalProperties response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{}}')
						end)
					

						--hmi side: expect UI.SetGlobalProperties request
						EXPECT_HMICALL("UI.SetGlobalProperties",
						{
							menuTitle = title_to_check,
							menuIcon = {
											imageType = "DYNAMIC",
											value = icon_to_check
										},
							vrHelpTitle = "Test Application",
							keyboardProperties = 
							{
								keyboardLayout = "QWERTY",
								autoCompleteText = "",
								language = "EN-US"
							},
							vrHelp = nil
						})
						
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{}}')
						end)								
						
						--mobile side: expect ResetGlobalProperties response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End NegativeResponseCheck.5.19				
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.5.20
				--Description: Check UI response with wrong type of method
					function Test:ResetGlobalProperties_UIResponseMethodWrongtype() 
						--mobile side: sending ResetGlobalProperties request
						local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
						{
							properties = 
							{
								"VRHELPTITLE",
								"MENUNAME",
								"MENUICON",
								"KEYBOARDPROPERTIES",
								"VRHELPITEMS",
								"HELPPROMPT",
								"TIMEOUTPROMPT"
							}
						})
						--hmi side: expect TTS.SetGlobalProperties request
						EXPECT_HMICALL("TTS.SetGlobalProperties",
						{
							helpPrompt = 
							{
								{
									type = "TEXT",
									text = textPromtValue[1]
								},
								{
									type = "TEXT",
									text = textPromtValue[2]
								}
							},
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
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending TTS.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
					

						--hmi side: expect UI.SetGlobalProperties request
						EXPECT_HMICALL("UI.SetGlobalProperties",
						{
							menuTitle = title_to_check,
							menuIcon = {
											imageType = "DYNAMIC",
											value = icon_to_check
										},
							vrHelpTitle = "Test Application",
							keyboardProperties = 
							{
								keyboardLayout = "QWERTY",
								autoCompleteText = "",
								language = "EN-US"
							},
							vrHelp = nil
						})
						
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, 1234, "SUCCESS", {})
						end)			
							
						--mobile side: expect ResetGlobalProperties response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
						:Timeout(12000)
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
						:Timeout(12000)
					end				
				--End Test case NegativeResponseCheck.5.20
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.5.21
				--Description: Check TTS response with wrong type of method
					function Test:ResetGlobalProperties_TTSResponseMethodWrongtype() 
						--mobile side: sending ResetGlobalProperties request
						local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
						{
							properties = 
							{
								"VRHELPTITLE",
								"MENUNAME",
								"MENUICON",
								"KEYBOARDPROPERTIES",
								"VRHELPITEMS",
								"HELPPROMPT",
								"TIMEOUTPROMPT"
							}
						})
						--hmi side: expect TTS.SetGlobalProperties request
						EXPECT_HMICALL("TTS.SetGlobalProperties",
						{
							helpPrompt = 
							{
								{
									type = "TEXT",
									text = textPromtValue[1]
								},
								{
									type = "TEXT",
									text = textPromtValue[2]
								}
							},
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
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending TTS.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, 1234, "SUCCESS", {})
						end)
					

						--hmi side: expect UI.SetGlobalProperties request
						EXPECT_HMICALL("UI.SetGlobalProperties",
						{
							menuTitle = title_to_check,
							menuIcon = {
											imageType = "DYNAMIC",
											value = icon_to_check
										},
							vrHelpTitle = "Test Application",
							keyboardProperties = 
							{
								keyboardLayout = "QWERTY",
								autoCompleteText = "",
								language = "EN-US"
							},
							vrHelp = nil
						})
						
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)				
							
						--mobile side: expect ResetGlobalProperties response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })						
						:Timeout(12000)
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
						:Timeout(12000)
					end				
				--End Test case NegativeResponseCheck.5.21
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.5.22
				--Description: Check UI TTS response with wrong type of method
					function Test:ResetGlobalProperties_UITTSResponseMethodWrongtype() 
						--mobile side: sending ResetGlobalProperties request
						local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
						{
							properties = 
							{
								"VRHELPTITLE",
								"MENUNAME",
								"MENUICON",
								"KEYBOARDPROPERTIES",
								"VRHELPITEMS",
								"HELPPROMPT",
								"TIMEOUTPROMPT"
							}
						})
						--hmi side: expect TTS.SetGlobalProperties request
						EXPECT_HMICALL("TTS.SetGlobalProperties",
						{
							helpPrompt = 
							{
								{
									type = "TEXT",
									text = textPromtValue[1]
								},
								{
									type = "TEXT",
									text = textPromtValue[2]
								}
							},
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
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending TTS.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, 1234, "SUCCESS", {})
						end)
					

						--hmi side: expect UI.SetGlobalProperties request
						EXPECT_HMICALL("UI.SetGlobalProperties",
						{
							menuTitle = title_to_check,
							menuIcon = {
											imageType = "DYNAMIC",
											value = icon_to_check
										},
							vrHelpTitle = "Test Application",
							keyboardProperties = 
							{
								keyboardLayout = "QWERTY",
								autoCompleteText = "",
								language = "EN-US"
							},
							vrHelp = nil
						})
						
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, 1234, "SUCCESS", {})
						end)				
							
						--mobile side: expect ResetGlobalProperties response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })						
						:Timeout(12000)
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
						:Timeout(12000)
					end				
				--End Test case NegativeResponseCheck.5.22
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.5.23
				--Description: Check UI response with wrong type of resultCode
					function Test:ResetGlobalProperties_UIResponseResultCodeWrongtype() 
						--mobile side: sending ResetGlobalProperties request
						local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
						{
							properties = 
							{
								"VRHELPTITLE",
								"MENUNAME",
								"MENUICON",
								"KEYBOARDPROPERTIES",
								"VRHELPITEMS",
								"HELPPROMPT",
								"TIMEOUTPROMPT"
							}
						})
						--hmi side: expect TTS.SetGlobalProperties request
						EXPECT_HMICALL("TTS.SetGlobalProperties",
						{
							helpPrompt = 
							{
								{
									type = "TEXT",
									text = textPromtValue[1]
								},
								{
									type = "TEXT",
									text = textPromtValue[2]
								}
							},
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
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending TTS.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
					

						--hmi side: expect UI.SetGlobalProperties request
						EXPECT_HMICALL("UI.SetGlobalProperties",
						{
							menuTitle = title_to_check,
							menuIcon = {
											imageType = "DYNAMIC",
											value = icon_to_check
										},
							vrHelpTitle = "Test Application",
							keyboardProperties = 
							{
								keyboardLayout = "QWERTY",
								autoCompleteText = "",
								language = "EN-US"
							},
							vrHelp = nil
						})
						
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.ResetGlobalProperties", "code":true}}')
						end)								
						
						--mobile side: expect ResetGlobalProperties response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })	
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)				
					end				
				--End Test case NegativeResponseCheck.5.23
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.5.24
				--Description: Check TTS response with wrong type of resultCode
					function Test:ResetGlobalProperties_TTSResponseResultCodeWrongtype() 
						--mobile side: sending ResetGlobalProperties request
						local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
						{
							properties = 
							{
								"VRHELPTITLE",
								"MENUNAME",
								"MENUICON",
								"KEYBOARDPROPERTIES",
								"VRHELPITEMS",
								"HELPPROMPT",
								"TIMEOUTPROMPT"
							}
						})
						--hmi side: expect TTS.SetGlobalProperties request
						EXPECT_HMICALL("TTS.SetGlobalProperties",
						{
							helpPrompt = 
							{
								{
									type = "TEXT",
									text = textPromtValue[1]
								},
								{
									type = "TEXT",
									text = textPromtValue[2]
								}
							},
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
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending TTS.SetGlobalProperties response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"TTS.ResetGlobalProperties", "code":true}}')
						end)
					

						--hmi side: expect UI.SetGlobalProperties request
						EXPECT_HMICALL("UI.SetGlobalProperties",
						{
							menuTitle = title_to_check,
							menuIcon = {
											imageType = "DYNAMIC",
											value = icon_to_check
										},
							vrHelpTitle = "Test Application",
							keyboardProperties = 
							{
								keyboardLayout = "QWERTY",
								autoCompleteText = "",
								language = "EN-US"
							},
							vrHelp = nil
						})
						
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)								
						
						--mobile side: expect ResetGlobalProperties response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })		
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)			
					end				
				--End Test case NegativeResponseCheck.5.24	
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.5.25
				--Description: Check UI TTS response with wrong type of resultCode
					function Test:ResetGlobalProperties_UITTSResponseResultCodeWrongtype() 
						--mobile side: sending ResetGlobalProperties request
						local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
						{
							properties = 
							{
								"VRHELPTITLE",
								"MENUNAME",
								"MENUICON",
								"KEYBOARDPROPERTIES",
								"VRHELPITEMS",
								"HELPPROMPT",
								"TIMEOUTPROMPT"
							}
						})
						--hmi side: expect TTS.SetGlobalProperties request
						EXPECT_HMICALL("TTS.SetGlobalProperties",
						{
							helpPrompt = 
							{
								{
									type = "TEXT",
									text = textPromtValue[1]
								},
								{
									type = "TEXT",
									text = textPromtValue[2]
								}
							},
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
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending TTS.SetGlobalProperties response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"TTS.ResetGlobalProperties", "code":true}}')
						end)
					

						--hmi side: expect UI.SetGlobalProperties request
						EXPECT_HMICALL("UI.SetGlobalProperties",
						{
							menuTitle = title_to_check,
							menuIcon = {
											imageType = "DYNAMIC",
											value = icon_to_check
										},
							vrHelpTitle = "Test Application",
							keyboardProperties = 
							{
								keyboardLayout = "QWERTY",
								autoCompleteText = "",
								language = "EN-US"
							},
							vrHelp = nil
						})
						
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.ResetGlobalProperties", "code":true}}')
						end)								
						
						--mobile side: expect ResetGlobalProperties response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })	
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)				
					end				
				--End Test case NegativeResponseCheck.5.25

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.5.26
				--Description: Check UI response with invalid json
					function Test: ResetGlobalProperties_UIResponseInvalidJson()	
						--mobile side: sending ResetGlobalProperties request
						local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
						{
							properties = 
							{
								"VRHELPTITLE",
								"MENUNAME",
								"MENUICON",
								"KEYBOARDPROPERTIES",
								"VRHELPITEMS",
								"HELPPROMPT",
								"TIMEOUTPROMPT"
							}
						})
						--hmi side: expect TTS.SetGlobalProperties request
						EXPECT_HMICALL("TTS.SetGlobalProperties",
						{
							helpPrompt = 
							{
								{
									type = "TEXT",
									text = textPromtValue[1]
								},
								{
									type = "TEXT",
									text = textPromtValue[2]
								}
							},
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
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending TTS.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
					

						--hmi side: expect UI.SetGlobalProperties request
						EXPECT_HMICALL("UI.SetGlobalProperties",
						{
							menuTitle = title_to_check,
							menuIcon = {
											imageType = "DYNAMIC",
											value = icon_to_check
										},
							vrHelpTitle = "Test Application",
							keyboardProperties = 
							{
								keyboardLayout = "QWERTY",
								autoCompleteText = "",
								language = "EN-US"
							},
							vrHelp = nil
						})
						
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							self.hmiConnection:Send('{"id"'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.ResetGlobalProperties", "code":0}}')
						end)								
						
						--mobile side: expect ResetGlobalProperties response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeResponseCheck.5.26
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.5.27
				--Description: Check TTS response with invalid json
					function Test: ResetGlobalProperties_TTSResponseInvalidJson()	
						--mobile side: sending ResetGlobalProperties request
						local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
						{
							properties = 
							{
								"VRHELPTITLE",
								"MENUNAME",
								"MENUICON",
								"KEYBOARDPROPERTIES",
								"VRHELPITEMS",
								"HELPPROMPT",
								"TIMEOUTPROMPT"
							}
						})
						--hmi side: expect TTS.SetGlobalProperties request
						EXPECT_HMICALL("TTS.SetGlobalProperties",
						{
							helpPrompt = 
							{
								{
									type = "TEXT",
									text = textPromtValue[1]
								},
								{
									type = "TEXT",
									text = textPromtValue[2]
								}
							},
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
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending TTS.SetGlobalProperties response
							self.hmiConnection:Send('{"id"'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"TTS.ResetGlobalProperties", "code":0}}')
						end)
					

						--hmi side: expect UI.SetGlobalProperties request
						EXPECT_HMICALL("UI.SetGlobalProperties",
						{
							menuTitle = title_to_check,
							menuIcon = {
											imageType = "DYNAMIC",
											value = icon_to_check
										},
							vrHelpTitle = "Test Application",
							keyboardProperties = 
							{
								keyboardLayout = "QWERTY",
								autoCompleteText = "",
								language = "EN-US"
							},
							vrHelp = nil
						})
						
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)								
						
						--mobile side: expect ResetGlobalProperties response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeResponseCheck.5.27
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.5.28
				--Description: Check UI TTS response with invalid json
					function Test: ResetGlobalProperties_UITTSResponseInvalidJson()	
						--mobile side: sending ResetGlobalProperties request
						local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
						{
							properties = 
							{
								"VRHELPTITLE",
								"MENUNAME",
								"MENUICON",
								"KEYBOARDPROPERTIES",
								"VRHELPITEMS",
								"HELPPROMPT",
								"TIMEOUTPROMPT"
							}
						})
						--hmi side: expect TTS.SetGlobalProperties request
						EXPECT_HMICALL("TTS.SetGlobalProperties",
						{
							helpPrompt = 
							{
								{
									type = "TEXT",
									text = textPromtValue[1]
								},
								{
									type = "TEXT",
									text = textPromtValue[2]
								}
							},
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
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending TTS.SetGlobalProperties response
							self.hmiConnection:Send('{"id"'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"TTS.ResetGlobalProperties", "code":0}}')
						end)
					

						--hmi side: expect UI.SetGlobalProperties request
						EXPECT_HMICALL("UI.SetGlobalProperties",
						{
							menuTitle = title_to_check,
							menuIcon = {
											imageType = "DYNAMIC",
											value = icon_to_check
										},
							vrHelpTitle = "Test Application",
							keyboardProperties = 
							{
								keyboardLayout = "QWERTY",
								autoCompleteText = "",
								language = "EN-US"
							},
							vrHelp = nil
						})
						
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							self.hmiConnection:Send('{"id"'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.ResetGlobalProperties", "code":0}}')
						end)								
						
						--mobile side: expect ResetGlobalProperties response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeResponseCheck.5.28			
			--End Test case NegativeResponseCheck.5
]]
		--End Test suit NegativeResponseCheck				

----------------------------------------------------------------------------------------------
----------------------------------------IV TEST BLOCK-----------------------------------------
---------------------------------------Result code check--------------------------------------
----------------------------------------------------------------------------------------------

	--Check all uncovered pairs resultCodes+success

	--Begin Test suit ResultCodeCheck
	--Description: check result code of response to Mobile

	
		--Begin Test case ResultCodeCheck.1
		--Description: Check UI resultCode SUCCESS

			--Requirement id in JAMA: SDLAQ-CRS-394

			--Verification criteria: The request ResetGlobalProperties is sent and executed successfully. A reset has been made. The SUCCESS response code is returned. 
			
			-- Covered in block I
			
		--End Test case ResultCodeCheck.1
		-----------------------------------------------------------------------------------------

		--Begin Test case ResultCodeCheck.2
		--Description: Check UI resultCode INVALID_DATA

			--Requirement id in JAMA: SDLAQ-CRS-395

			--Verification criteria: SDL responses INVALID_DATA

			function Test:ResetGlobalProperties_ResultCode()
			
				--mobile side: sending ResetGlobalProperties request
				local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
				{
					properties = 
					{
						"VRHELPTITLE123",
						"MENUNAME",
						"MENUICON",
						"KEYBOARDPROPERTIES",
						"VRHELPITEMS",
						"HELPPROMPT",
						"TIMEOUTPROMPT"
					}
				})
			

				--hmi side: expect TTS.SetGlobalProperties request
				EXPECT_HMICALL("TTS.SetGlobalProperties", {})
				:Timeout(iTimeout)
				:Times(0)
			

				--hmi side: expect UI.SetGlobalProperties request
				EXPECT_HMICALL("UI.SetGlobalProperties", {})
				:Timeout(iTimeout)
				:Times(0)


				--mobile side: expect ResetGlobalProperties response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
				:Timeout(iTimeout)
				
				EXPECT_NOTIFICATION("OnHashChange")
				:Timeout(iTimeout)
				:Times(0)				
			end

		--End Test case ResultCodeCheck.2
		-----------------------------------------------------------------------------------------

		--Begin Test case ResultCodeCheck.3
		--Description: Check UI resultCode OUT_OF_MEMORY

			--Requirement id in JAMA: SDLAQ-CRS-396

			--Verification criteria: The request ResetGlobalProperties is sent under conditions of RAM deficite for executing it. The response code OUT_OF_MEMORY is returned. 

			--Not applicable

		--End Test case ResultCodeCheck.3
		-----------------------------------------------------------------------------------------

		--Begin Test case ResultCodeCheck.4
		--Description: Check UI resultCode TOO_MANY_PENDING_REQUESTS

			--Requirement id in JAMA: SDLAQ-CRS-397

			--Verification criteria: The system sends the responses with TOO_MANY_PENDING_REQUESTS error code for all futher requests, until there are less than 1000 requests at a time that have not been responded by the system yet.
		
			-- Moved to another script
			
		--End Test case ResultCodeCheck.4
		-----------------------------------------------------------------------------------------

		--Begin Test case ResultCodeCheck.5
		--Description: Check UI resultCode APPLICATION_NOT_REGISTERED

			--Requirement id in JAMA: SDLAQ-CRS-398

			--Verification criteria: SDL sends APPLICATION_NOT_REGISTERED result code when the app sends the request within the same connection before RegisterAppInterface has been yet performed.
			
			commonSteps:precondition_AddNewSession() --return mobileSession2

			function Test:ResetGlobalProperties_ResultCode_APPLICATION_NOT_REGISTERED()
			
				--mobile side: sending ResetGlobalProperties request
				local cid = self.mobileSession2:SendRPC("ResetGlobalProperties",
				{
					properties = 
					{
						"VRHELPTITLE",
						"MENUNAME",
						"MENUICON",
						"KEYBOARDPROPERTIES",
						"VRHELPITEMS",
						"HELPPROMPT",
						"TIMEOUTPROMPT"
					}
				})
			

				--hmi side: expect TTS.SetGlobalProperties request
				EXPECT_HMICALL("TTS.SetGlobalProperties", {})
				:Timeout(iTimeout)
				:Times(0)

			

				--hmi side: expect UI.SetGlobalProperties request
				EXPECT_HMICALL("UI.SetGlobalProperties", {})
				:Timeout(iTimeout)
				:Times(0)

			

				--mobile side: expect ResetGlobalProperties response
				self.mobileSession2:ExpectResponse(cid, { success = false, resultCode = "APPLICATION_NOT_REGISTERED"})
				:Timeout(iTimeout)
				
				self.mobileSession2:ExpectNotification("OnHashChange", {})
				:Timeout(iTimeout)
				:Times(0)				
			end
	
		--End Test case ResultCodeCheck.5
		-----------------------------------------------------------------------------------------

		--Begin Test case ResultCodeCheck.6
		--Description: Check UI resultCode REJECTED

			--Requirement id in JAMA: SDLAQ-CRS-399

			--Verification criteria: HMI is expected to return REJECTED result code in case HMI is currently busy with a higher-priority event.
			
			--Begin Test case ResultCodeCheck.6.1
			--Description: UI response REJECTED
				function Test:ResetGlobalProperties_UIREJECTED()
				
					--mobile side: sending ResetGlobalProperties request
					local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
					{
						properties = 
						{
							"VRHELPTITLE",
							"MENUNAME",
							"MENUICON",
							"KEYBOARDPROPERTIES",
							"VRHELPITEMS",
							"HELPPROMPT",
							"TIMEOUTPROMPT"
						}
					})
				

					--hmi side: expect TTS.SetGlobalProperties request
					EXPECT_HMICALL("TTS.SetGlobalProperties", {})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)

				

					--hmi side: expect UI.SetGlobalProperties request
					EXPECT_HMICALL("UI.SetGlobalProperties", {})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						self.hmiConnection:SendError(data.id, data.method, "REJECTED", "")
					end)
				

					--mobile side: expect ResetGlobalProperties response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "REJECTED"})
					
					EXPECT_NOTIFICATION("OnHashChange")					
					:Times(0)				
				end
			--End Test case ResultCodeCheck.6.1
			
			-----------------------------------------------------------------------------------------
						
			--Begin Test case ResultCodeCheck.6.2
			--Description: TTS response REJECTED
				function Test:ResetGlobalProperties_TTSREJECTED()
				
					--mobile side: sending ResetGlobalProperties request
					local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
					{
						properties = 
						{
							"VRHELPTITLE",
							"MENUNAME",
							"MENUICON",
							"KEYBOARDPROPERTIES",
							"VRHELPITEMS",
							"HELPPROMPT",
							"TIMEOUTPROMPT"
						}
					})
				

					--hmi side: expect TTS.SetGlobalProperties request
					EXPECT_HMICALL("TTS.SetGlobalProperties", {})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						self.hmiConnection:SendError(data.id, data.method, "REJECTED", "")
					end)


					--hmi side: expect UI.SetGlobalProperties request
					EXPECT_HMICALL("UI.SetGlobalProperties", {})					
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)

				
					--mobile side: expect ResetGlobalProperties response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "REJECTED"})
					
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)			
				end
			--End Test case ResultCodeCheck.6.2
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case ResultCodeCheck.6.3
			--Description: UI & TTS response REJECTED
				function Test:ResetGlobalProperties_UITTSREJECTED()
				
					--mobile side: sending ResetGlobalProperties request
					local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
					{
						properties = 
						{
							"VRHELPTITLE",
							"MENUNAME",
							"MENUICON",
							"KEYBOARDPROPERTIES",
							"VRHELPITEMS",
							"HELPPROMPT",
							"TIMEOUTPROMPT"
						}
					})
				

					--hmi side: expect TTS.SetGlobalProperties request
					EXPECT_HMICALL("TTS.SetGlobalProperties", {})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						self.hmiConnection:SendError(data.id, data.method, "REJECTED", "")
					end)

				

					--hmi side: expect UI.SetGlobalProperties request
					EXPECT_HMICALL("UI.SetGlobalProperties", {})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						self.hmiConnection:SendError(data.id, data.method, "REJECTED", "")
					end)

					--mobile side: expect ResetGlobalProperties response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "REJECTED"})
					
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)				
				end
			--End Test case ResultCodeCheck.6.3			
		--End Test case ResultCodeCheck.6
		-----------------------------------------------------------------------------------------

		--Begin Test case ResultCodeCheck.7
		--Description: Check UI resultCode GENERIC_ERROR

			--Requirement id in JAMA: SDLAQ-CRS-400

			--Verification criteria: GENERIC_ERROR comes as a result code in response when all other codes aren't applicable or the unknown issue occured. Success=false

			--Begin Test case ResultCodeCheck.7.1
			--Description: UI response GENERIC_ERROR
				function Test:ResetGlobalProperties_UI_ResponseError()
				
					--mobile side: sending ResetGlobalProperties request
					local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
					{
						properties = 
						{
							"VRHELPTITLE",
							"MENUNAME",
							"MENUICON",
							"KEYBOARDPROPERTIES",
							"VRHELPITEMS",
							"HELPPROMPT",
							"TIMEOUTPROMPT"
						}
					})
				

					--hmi side: expect TTS.SetGlobalProperties request
					EXPECT_HMICALL("TTS.SetGlobalProperties", {})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)


					--hmi side: expect UI.SetGlobalProperties request
					EXPECT_HMICALL("UI.SetGlobalProperties", {})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "")
					end)

					
					--mobile side: expect ResetGlobalProperties response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
					:Timeout(12000)
					

					EXPECT_NOTIFICATION("OnHashChange")
					--UPDATED according to APPLNIK-15682
					--:Timeout(12000)				
					:Times(0)
					
				end
			--End Test case ResultCodeCheck.7.1
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case ResultCodeCheck.7.2
			--Description: TTS response GENERIC_ERROR
			function Test:ResetGlobalProperties_TTS_ResponseError()
			
				--mobile side: sending ResetGlobalProperties request
				local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
				{
					properties = 
					{
						"VRHELPTITLE",
						"MENUNAME",
						"MENUICON",
						"KEYBOARDPROPERTIES",
						"VRHELPITEMS",
						"HELPPROMPT",
						"TIMEOUTPROMPT"
					}
				})
			

				--hmi side: expect TTS.SetGlobalProperties request
				EXPECT_HMICALL("TTS.SetGlobalProperties", {})
				:Timeout(iTimeout)
				:Do(function(_,data)
					--hmi side: sending UI.SetGlobalProperties response
					self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "")
				end)

			

				--hmi side: expect UI.SetGlobalProperties request
				EXPECT_HMICALL("UI.SetGlobalProperties", {})
				:Timeout(iTimeout)
				:Do(function(_,data)
					--hmi side: sending UI.SetGlobalProperties response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)

			

				--mobile side: expect ResetGlobalProperties response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
				:Timeout(12000)
				
				EXPECT_NOTIFICATION("OnHashChange")
				--UPDATED according to APPLNIK-15682
				--:Timeout(12000)				
				:Times(0)
			end
			--End Test case ResultCodeCheck.7.2
			
			-----------------------------------------------------------------------------------------
			--Begin Test case ResultCodeCheck.7.2
			--Description: UI & TTS response GENERIC_ERROR
			function Test:ResetGlobalProperties_UITTS_ResponseError()
			
				--mobile side: sending ResetGlobalProperties request
				local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
				{
					properties = 
					{
						"VRHELPTITLE",
						"MENUNAME",
						"MENUICON",
						"KEYBOARDPROPERTIES",
						"VRHELPITEMS",
						"HELPPROMPT",
						"TIMEOUTPROMPT"
					}
				})
			

				--hmi side: expect TTS.SetGlobalProperties request
				EXPECT_HMICALL("TTS.SetGlobalProperties", {})
				:Timeout(iTimeout)
				:Do(function(_,data)
					--hmi side: sending UI.SetGlobalProperties response
					self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "")
				end)

			

				--hmi side: expect UI.SetGlobalProperties request
				EXPECT_HMICALL("UI.SetGlobalProperties", {})
				:Timeout(iTimeout)
				:Do(function(_,data)
					--hmi side: sending UI.SetGlobalProperties response
					self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "")
				end)

			

				--mobile side: expect ResetGlobalProperties response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
				:Timeout(12000)
				
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)				
			end
						
		--End Test case ResultCodeCheck.7
		-----------------------------------------------------------------------------------------

		--Begin Test case ResultCodeCheck.8
		--Description: Check UI resultCode DISALLOWED

			--Requirement id in JAMA: SDLAQ-CRS-401

			--Verification criteria: 
				-- SDL must return "resultCode: DISALLOWED, success:false" to the RPC in case this RPC is omitted in the PolicyTable group(s) assigned to the app that requests this RPC.
				-- SDL must return "resultCode: DISALLOWED, success:false" to the RPC in case this RPC is included to the PolicyTable group(s) assigned to the app that requests this RPC and the group has not yet received user's consents.

			--Begin Test case ResultCodeCheck.8.1
			--Description: SDL send DISALLOWED when HMI level is NONE
			
				-- Precondition: Change app to NONE HMI level
				commonSteps:DeactivateAppToNoneHmiLevel()

				function Test:ResetGlobalProperties_SuccessHMINone()
					--mobile side: sending ResetGlobalProperties request
					local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
															{
																properties = 
																{
																	"VRHELPTITLE",
																	"MENUNAME",
																	"MENUICON",
																	"KEYBOARDPROPERTIES",
																	"VRHELPITEMS",
																	"HELPPROMPT",
																	"TIMEOUTPROMPT"
																}
															})
				
					--UPDATED: Accoridng to APPLINK-19314
					-- --hmi side: expect TTS.SetGlobalProperties request
					-- EXPECT_HMICALL("TTS.SetGlobalProperties")
					-- 	:Timeout(iTimeout)
					-- 	:Do(function(_,data)
					-- 		--hmi side: sending UI.SetGlobalProperties response
					-- 		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					-- 	end)


					-- --hmi side: expect UI.SetGlobalProperties request
					-- EXPECT_HMICALL("UI.SetGlobalProperties")
					-- 	:Timeout(iTimeout)
					-- 	:Do(function(_,data)
					-- 		--hmi side: sending UI.SetGlobalProperties response
					-- 		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					-- 	end)

					
					-- --mobile side: expect ResetGlobalProperties response
					-- EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
					
					-- EXPECT_NOTIFICATION("OnHashChange")
					--END UPDATED

					--mobile side: expect ResetGlobalProperties response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED"})
					
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)

				end	
			
				--Postcondition: Activate app
				commonSteps:ActivationApp()
		
			--Begin Test case ResultCodeCheck.8.1
			
			-----------------------------------------------------------------------------------------
--[[TODO: uncomment after ATF defect APPLINK-13101 resolved	
		
			--Begin Test case ResultCodeCheck.8.2
			--Description: ResetGlobalProperties is omitted in the PolicyTable group(s)

				--Precondition: Build policy table file
				local PTName = testCasesForPolicyTable:createPolicyTableWithoutAPI(APIName)
				
				--Precondition: Update policy table
				testCasesForPolicyTable:updatePolicy(PTName)
				
								
				--Check of DISALLOWED response code
				function Test:ResetGlobalProperties_Disallowed()
					--mobile side: sending ResetGlobalProperties request
					local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
					{
						properties = 
						{
							"VRHELPTITLE",
							"MENUNAME",
							"MENUICON",
							"KEYBOARDPROPERTIES",
							"VRHELPITEMS",
							"HELPPROMPT",
							"TIMEOUTPROMPT"
						}
					})	
						
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED" })
					:Timeout(20000)
						
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end

			--End Test case ResultCodeCheck.8.2			
		
			-----------------------------------------------------------------------------------------	
			
			--Begin Test case ResultCodeCheck.8.3
			--Description: USER-DISALLOWED response code is sent by SDL when the request isn't allowed by user.
			
				--Precondition: Build policy table file
				local HmiLevels = {"FULL", "LIMITED", "BACKGROUND"}
				local PTName = testCasesForPolicyTable:createPolicyTable(APIName, HmiLevels)
				
				--Precondition: Update policy table
				local groupID = testCasesForPolicyTable:updatePolicy(PTName, "group1")
				
				--Precondition: User does not allow function group
				testCasesForPolicyTable:userConsent(groupID, "group1", false)	
				
				--Check of USER_DISALLOWED response code
				function Test:ResetGlobalProperties_UserDisallowed()
					--mobile side: sending ResetGlobalProperties request
					local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
					{
						properties = 
						{
							"VRHELPTITLE",
							"MENUNAME",
							"MENUICON",
							"KEYBOARDPROPERTIES",
							"VRHELPITEMS",
							"HELPPROMPT",
							"TIMEOUTPROMPT"
						}
					})	
						
					EXPECT_RESPONSE(cid, { success = false, resultCode = "USER_DISALLOWED" })
					:Timeout(20000)
						
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end

				--Postcondition: User allows function group
				testCasesForPolicyTable:userConsent(groupID, "group1", true)	
				
		--End Test case ResultCodeCheck.8.3
	--End Test case ResultCodeCheck.8
]]		
	--End Test suit ResultCodeCheck
	
----------------------------------------------------------------------------------------------
-----------------------------------------V TEST BLOCK-----------------------------------------
---------------------------------------HMI negative cases-------------------------------------
----------------------------------------------------------------------------------------------

		--------Checks-----------
	-- requests without responses from HMI
	-- invalid structure os response
	-- several responses from HMI to one request
	-- fake parameters
	-- HMI correlation id check 
	-- wrong response with correct HMI id
	
	
	--Begin Test suit HMINegativeCheck
	--Description: Check negative response from HMI

		--Begin Test suit HMINegativeCheck.1
		--Description: check requests without responses from HMI
			
			--Requirement id in JAMA: SDLAQ-CRS-400

			--Verification criteria: In case SDL splits the request from mobile app to several HMI interfaces AND one of the interfaces does not respond during SDL`s watchdog (important note: this component is working and has responded to previous RPCs), SDL must return "GENERIC_ERROR, success: false" result to mobile app AND include appropriate description into "info" parameter.
				
			--Begin Test case HMINegativeCheck.1.1
			--Description: Check ResetGlobalProperties requests without UI responses from HMI

				function Test:ResetGlobalProperties_RequestWithoutUIResponsesFromHMI()
				
					--mobile side: sending ResetGlobalProperties request
					local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
					{
						properties = 
						{
							"VRHELPTITLE",
							"MENUNAME",
							"MENUICON",
							"KEYBOARDPROPERTIES",
							"VRHELPITEMS",
							"HELPPROMPT",
							"TIMEOUTPROMPT"
						}
					})
				

					--hmi side: expect TTS.SetGlobalProperties request
					EXPECT_HMICALL("TTS.SetGlobalProperties", {})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)

					--hmi side: expect UI.SetGlobalProperties request
					EXPECT_HMICALL("UI.SetGlobalProperties", {})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						--self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)				

					--mobile side: expect ResetGlobalProperties response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "UI component does not respond"})
					:Timeout(12000)
					
					EXPECT_NOTIFICATION("OnHashChange")
					:Timeout(12000)
					:Times(0)					
				end

			--End Test case HMINegativeCheck.1.1
			-----------------------------------------------------------------------------------------

			--Begin Test case HMINegativeCheck.1.2
			--Description: Check ResetGlobalProperties requests without TTS responses from HMI

				function Test:ResetGlobalProperties_RequestWithoutTTSResponsesFromHMI()
				
					--mobile side: sending ResetGlobalProperties request
					local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
					{
						properties = 
						{
							"VRHELPTITLE",
							"MENUNAME",
							"MENUICON",
							"KEYBOARDPROPERTIES",
							"VRHELPITEMS",
							"HELPPROMPT",
							"TIMEOUTPROMPT"
						}
					})
				
					--hmi side: expect TTS.SetGlobalProperties request
					EXPECT_HMICALL("TTS.SetGlobalProperties", {})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						--self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)
					
					--hmi side: expect UI.SetGlobalProperties request
					EXPECT_HMICALL("UI.SetGlobalProperties", {})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)

				

					--mobile side: expect ResetGlobalProperties response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "TTS component does not respond"})
					:Timeout(12000)
					
					EXPECT_NOTIFICATION("OnHashChange")
					:Timeout(12000)
					--UPDATED according to APPLNIK-15682
					--:Times(1)					
					:Times(0)					
				end

			--End Test case HMINegativeCheck.1.2
			-----------------------------------------------------------------------------------------

			--Begin Test case HMINegativeCheck.1.3
			--Description: Check ResetGlobalProperties requests without responses from HMI

				function Test:ResetGlobalProperties_RequestWithoutResponsesFromHMI()
				
					--mobile side: sending ResetGlobalProperties request
					local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
					{
						properties = 
						{
							"VRHELPTITLE",
							"MENUNAME",
							"MENUICON",
							"KEYBOARDPROPERTIES",
							"VRHELPITEMS",
							"HELPPROMPT",
							"TIMEOUTPROMPT"
						}
					})
				

					--mobile side: expect ResetGlobalProperties response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "UI component does not respond. TTS component does not respond"})
					:Timeout(12000)
					
					EXPECT_NOTIFICATION("OnHashChange")
					:Timeout(12000)
					:Times(0)					
				end

			--End Test case HMINegativeCheck.1.3
		--End Test suit HMINegativeCheck.1
			
		-----------------------------------------------------------------------------------------
		
		--Begin Test suit HMINegativeCheck.2
		--Description: invalid structure of response
			
			--Requirement id in JAMA: SDLAQ-CRS-11

			--Verification criteria: The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.

			--Begin Test case HMINegativeCheck.2.1
			--Description: Check responses from HMI (UI) with invalid structure

--ToDo: Only run this test case when APPLINK-13418 is fixed.
--[[
				function Test:ResetGlobalProperties_UI_InvalidStructureOfResponse()
				
					--mobile side: sending ResetGlobalProperties request
					local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
					{
						properties = 
						{
							"VRHELPTITLE",
							"MENUNAME",
							"MENUICON",
							"KEYBOARDPROPERTIES",
							"VRHELPITEMS",
							"HELPPROMPT",
							"TIMEOUTPROMPT"
						}
					})
				

					--hmi side: expect TTS.SetGlobalProperties request
					EXPECT_HMICALL("TTS.SetGlobalProperties", {})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)

				

					--hmi side: expect UI.SetGlobalProperties request
					EXPECT_HMICALL("UI.SetGlobalProperties", {})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0", "code":0, "result":{"method":"UI.SetGlobalProperties"}}')
					end)

				

					--mobile side: expect ResetGlobalProperties response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
					:Timeout(iTimeout)

					EXPECT_NOTIFICATION("OnHashChange")
					:Timeout(12000)
					:Times(0)					
				end
]]--
			--End Test case HMINegativeCheck.2.1
			-----------------------------------------------------------------------------------------

			--Begin Test case HMINegativeCheck.2.2
			--Description: Check responses from HMI (TTS) with invalid structure

				
--ToDo: Only run this test case when APPLINK-13418 is fixed.				
--[[
				function Test:ResetGlobalProperties_TTS_InvalidStructureOfResponse()
				
					--mobile side: sending ResetGlobalProperties request
					local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
					{
						properties = 
						{
							"VRHELPTITLE",
							"MENUNAME",
							"MENUICON",
							"KEYBOARDPROPERTIES",
							"VRHELPITEMS",
							"HELPPROMPT",
							"TIMEOUTPROMPT"
						}
					})
				

					--hmi side: expect TTS.SetGlobalProperties request
					EXPECT_HMICALL("TTS.SetGlobalProperties", {})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0", "code":0, "result":{"method":"TTS.SetGlobalProperties"}}')
					end)

				

					--hmi side: expect UI.SetGlobalProperties request
					EXPECT_HMICALL("UI.SetGlobalProperties", {})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)

				

					--mobile side: expect ResetGlobalProperties response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
					:Timeout(iTimeout)

					EXPECT_NOTIFICATION("OnHashChange")
					:Timeout(12000)
					:Times(0)					
				end
]]--
			--End Test case HMINegativeCheck.2.2
			-----------------------------------------------------------------------------------------
			
		--End Test suit HMINegativeCheck.2
		
		-----------------------------------------------------------------------------------------
		
		--Begin Test suit HMINegativeCheck.3
		--Description: several responses from HMI to one request
		
			--Requirement id in JAMA: SDLAQ-CRS-11

			--Verification criteria: The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
			
			--Begin Test case HMINegativeCheck.3.1
			--Description: Check several responses from HMI (UI) to one request

				function Test:ResetGlobalProperties_UI_SeveralResponseToOneRequest()
				
					--mobile side: sending ResetGlobalProperties request
					local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
					{
						properties = 
						{
							"VRHELPTITLE",
							"MENUNAME",
							"MENUICON",
							"KEYBOARDPROPERTIES",
							"VRHELPITEMS",
							"HELPPROMPT",
							"TIMEOUTPROMPT"
						}
					})
				

					--hmi side: expect TTS.SetGlobalProperties request
					EXPECT_HMICALL("TTS.SetGlobalProperties", {})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)

				

					--hmi side: expect UI.SetGlobalProperties request
					EXPECT_HMICALL("UI.SetGlobalProperties", {})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						self.hmiConnection:SendResponse(data.id, data.method, "INVALID_DATA", {})
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)

				

					--mobile side: expect ResetGlobalProperties response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
					:Timeout(iTimeout)
					
					EXPECT_NOTIFICATION("OnHashChange")
					:Timeout(12000)
					:Times(0)					
				end

			--End Test case HMINegativeCheck.3.1
			-----------------------------------------------------------------------------------------

			--Begin Test case HMINegativeCheck.3.2
			--Description: Check several responses from HMI (TTS) to one request

				function Test:ResetGlobalProperties_TTS_SeveralResponseToOneRequest()
				
					--mobile side: sending ResetGlobalProperties request
					local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
					{
						properties = 
						{
							"VRHELPTITLE",
							"MENUNAME",
							"MENUICON",
							"KEYBOARDPROPERTIES",
							"VRHELPITEMS",
							"HELPPROMPT",
							"TIMEOUTPROMPT"
						}
					})
				

					--hmi side: expect TTS.SetGlobalProperties request
					EXPECT_HMICALL("TTS.SetGlobalProperties", {})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						self.hmiConnection:SendResponse(data.id, data.method, "INVALID_DATA", {})
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)

				

					--hmi side: expect UI.SetGlobalProperties request
					EXPECT_HMICALL("UI.SetGlobalProperties", {})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)

				

					--mobile side: expect ResetGlobalProperties response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
					:Timeout(iTimeout)

					EXPECT_NOTIFICATION("OnHashChange")
					:Timeout(15000)
					:Times(0)					
				end

			--End Test case HMINegativeCheck.3.2
			-----------------------------------------------------------------------------------------

			--Begin Test case HMINegativeCheck.3.3
			--Description: Check several responses from HMI (UI & TTS) to one request

				function Test:ResetGlobalProperties_UITTS_SeveralResponseToOneRequest()
				
					--mobile side: sending ResetGlobalProperties request
					local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
					{
						properties = 
						{
							"VRHELPTITLE",
							"MENUNAME",
							"MENUICON",
							"KEYBOARDPROPERTIES",
							"VRHELPITEMS",
							"HELPPROMPT",
							"TIMEOUTPROMPT"
						}
					})
				

					--hmi side: expect TTS.SetGlobalProperties request
					EXPECT_HMICALL("TTS.SetGlobalProperties", {})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						self.hmiConnection:SendResponse(data.id, data.method, "INVALID_DATA", {})
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)

				

					--hmi side: expect UI.SetGlobalProperties request
					EXPECT_HMICALL("UI.SetGlobalProperties", {})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						self.hmiConnection:SendResponse(data.id, data.method, "INVALID_DATA", {})
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)

				

					--mobile side: expect ResetGlobalProperties response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
					:Timeout(iTimeout)

					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)					
				end

			--End Test case HMINegativeCheck.3.3			
		--End Test suit HMINegativeCheck.3

		-----------------------------------------------------------------------------------------
		
		--Begin Test suit HMINegativeCheck.4
		--Description: check response with fake parameters
			
			--Requirement id in JAMA:
				--SDLAQ-CRS-11

			--Verification criteria:
				--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
				
			--Begin Test case HMINegativeCheck.4.1
			--Description: Check responses from HMI (UI) with fake parameter

				function Test:ResetGlobalProperties_UI_ResponseWithFakeParamater()
				
					--mobile side: sending ResetGlobalProperties request
					local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
					{
						properties = 
						{
							"VRHELPTITLE",
							"MENUNAME",
							"MENUICON",
							"KEYBOARDPROPERTIES",
							"VRHELPITEMS",
							"HELPPROMPT",
							"TIMEOUTPROMPT"
						}
					})
				

					--hmi side: expect TTS.SetGlobalProperties request
					EXPECT_HMICALL("TTS.SetGlobalProperties", {})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)

				

					--hmi side: expect UI.SetGlobalProperties request
					EXPECT_HMICALL("UI.SetGlobalProperties", {})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {fakeParam = "fakeParam"})
					end)

					--mobile side: expect ResetGlobalProperties response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
					:ValidIf (function(_,data)
						if data.payload.fakeParam then
							print(" SDL resend fake parameter to mobile app ")
							return false
						else 
							return true
						end
					end)
						
					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")
				end

			--End Test case HMINegativeCheck.4.1
			
			-----------------------------------------------------------------------------------------

			--Begin Test case HMINegativeCheck.4.2
			--Description: Check responses from HMI (TTS) with fake parameter
				function Test:ResetGlobalProperties_TTS_ResponseWithFakeParamater()
				
					--mobile side: sending ResetGlobalProperties request
					local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
					{
						properties = 
						{
							"VRHELPTITLE",
							"MENUNAME",
							"MENUICON",
							"KEYBOARDPROPERTIES",
							"VRHELPITEMS",
							"HELPPROMPT",
							"TIMEOUTPROMPT"
						}
					})
				

					--hmi side: expect TTS.SetGlobalProperties request
					EXPECT_HMICALL("TTS.SetGlobalProperties", {})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {fakeParam = "fakeParam"})
					end)

					--hmi side: expect UI.SetGlobalProperties request
					EXPECT_HMICALL("UI.SetGlobalProperties", {})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)

				

					--mobile side: expect ResetGlobalProperties response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
					:ValidIf (function(_,data)
						if data.payload.fakeParam then
							print(" SDL resend fake parameter to mobile app ")
							return false
						else 
							return true
						end
					end)
						
					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")
				end

			--End Test case HMINegativeCheck.4.2
			
			-----------------------------------------------------------------------------------------

			--Begin Test case HMINegativeCheck.4.3
			--Description: Check responses from HMI (UI TTS) with fake parameter
				function Test:ResetGlobalProperties_UITTS_ResponseWithFakeParamater()
				
					--mobile side: sending ResetGlobalProperties request
					local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
					{
						properties = 
						{
							"VRHELPTITLE",
							"MENUNAME",
							"MENUICON",
							"KEYBOARDPROPERTIES",
							"VRHELPITEMS",
							"HELPPROMPT",
							"TIMEOUTPROMPT"
						}
					})
				

					--hmi side: expect TTS.SetGlobalProperties request
					EXPECT_HMICALL("TTS.SetGlobalProperties", {})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {fakeParam = "fakeParam"})
					end)

					--hmi side: expect UI.SetGlobalProperties request
					EXPECT_HMICALL("UI.SetGlobalProperties", {})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {fakeParam = "fakeParam"})
					end)

				

					--mobile side: expect ResetGlobalProperties response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
					:ValidIf (function(_,data)
						if data.payload.fakeParam then
							print(" SDL resend fake parameter to mobile app ")
							return false
						else 
							return true
						end
					end)
						
					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")
				end

			--End Test case HMINegativeCheck.4.3
			
			-----------------------------------------------------------------------------------------
			
				
			--Begin Test case HMINegativeCheck.4.4
			--Description: Check responses from HMI (UI) with parameter another api

				function Test:ResetGlobalProperties_UI_ResponseWithParamsFromOtherAPI()
				
					--mobile side: sending ResetGlobalProperties request
					local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
					{
						properties = 
						{
							"VRHELPTITLE",
							"MENUNAME",
							"MENUICON",
							"KEYBOARDPROPERTIES",
							"VRHELPITEMS",
							"HELPPROMPT",
							"TIMEOUTPROMPT"
						}
					})
				

					--hmi side: expect TTS.SetGlobalProperties request
					EXPECT_HMICALL("TTS.SetGlobalProperties", {})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)

				

					--hmi side: expect UI.SetGlobalProperties request
					EXPECT_HMICALL("UI.SetGlobalProperties", {})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {sliderPosition = 5})
					end)

					--mobile side: expect ResetGlobalProperties response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
					:ValidIf (function(_,data)
						if data.payload.sliderPosition then
							print(" SDL resend fake parameter to mobile app ")
							return false
						else 
							return true
						end
					end)
						
					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")
				end

			--End Test case HMINegativeCheck.4.4
			
			-----------------------------------------------------------------------------------------

			--Begin Test case HMINegativeCheck.4.5
			--Description: Check responses from HMI (TTS) with parameter another api
				function Test:ResetGlobalProperties_TTS_ResponseParamsFromOtherAPI()
				
					--mobile side: sending ResetGlobalProperties request
					local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
					{
						properties = 
						{
							"VRHELPTITLE",
							"MENUNAME",
							"MENUICON",
							"KEYBOARDPROPERTIES",
							"VRHELPITEMS",
							"HELPPROMPT",
							"TIMEOUTPROMPT"
						}
					})
				

					--hmi side: expect TTS.SetGlobalProperties request
					EXPECT_HMICALL("TTS.SetGlobalProperties", {})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {sliderPosition = 5})
					end)

					--hmi side: expect UI.SetGlobalProperties request
					EXPECT_HMICALL("UI.SetGlobalProperties", {})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)

				

					--mobile side: expect ResetGlobalProperties response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
					:ValidIf (function(_,data)
						if data.payload.sliderPosition then
							print(" SDL resend fake parameter to mobile app ")
							return false
						else 
							return true
						end
					end)
						
					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")
				end

			--End Test case HMINegativeCheck.4.5
			
			-----------------------------------------------------------------------------------------

			--Begin Test case HMINegativeCheck.4.6
			--Description: Check responses from HMI (UI TTS) with parameter another api
				function Test:ResetGlobalProperties_UITTS_ResponseParamsFromOtherAPI()
				
					--mobile side: sending ResetGlobalProperties request
					local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
					{
						properties = 
						{
							"VRHELPTITLE",
							"MENUNAME",
							"MENUICON",
							"KEYBOARDPROPERTIES",
							"VRHELPITEMS",
							"HELPPROMPT",
							"TIMEOUTPROMPT"
						}
					})
				

					--hmi side: expect TTS.SetGlobalProperties request
					EXPECT_HMICALL("TTS.SetGlobalProperties", {})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {sliderPosition = 5})
					end)

					--hmi side: expect UI.SetGlobalProperties request
					EXPECT_HMICALL("UI.SetGlobalProperties", {})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {sliderPosition = 5})
					end)

					--mobile side: expect ResetGlobalProperties response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
					:ValidIf (function(_,data)
						if data.payload.sliderPosition then
							print(" SDL resend fake parameter to mobile app ")
							return false
						else 
							return true
						end
					end)
						
					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")
				end
			--End Test case HMINegativeCheck.4.6			
		--End Test suit HMINegativeCheck.4

		-----------------------------------------------------------------------------------------
		
		--Begin Test suit HMINegativeCheck.5
		--Description: check response with different correlation id
		
			--Requirement id in JAMA: SDLAQ-CRS-11

			--Verification criteria: The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.\
			
			--Begin Test case HMINegativeCheck.5.1
			--Description: Check UI wrong response with correct HMI correlation id

--[[TODO update after resolving  APPLINK-14765
				function Test:ResetGlobalProperties_UI_WrongResponse_WithCorrectHMICorrelationId()
				
					--mobile side: sending ResetGlobalProperties request
					local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
					{
						properties = 
						{
							"VRHELPTITLE",
							"MENUNAME",
							"MENUICON",
							"KEYBOARDPROPERTIES",
							"VRHELPITEMS",
							"HELPPROMPT",
							"TIMEOUTPROMPT"
						}
					})
				

					--hmi side: expect TTS.SetGlobalProperties request
					EXPECT_HMICALL("TTS.SetGlobalProperties", {})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)

				

					--hmi side: expect UI.SetGlobalProperties request
					EXPECT_HMICALL("UI.SetGlobalProperties", {})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						self.hmiConnection:SendResponse(data.id, "UI.Show", "SUCCESS", {})
					end)

				

					--mobile side: expect ResetGlobalProperties response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
					:Timeout(12000)
					
					EXPECT_NOTIFICATION("OnHashChange")
					:Timeout(12000)
					:Times(0)					
				end

			--End Test case HMINegativeCheck.5.1
			-----------------------------------------------------------------------------------------

			--Begin Test case HMINegativeCheck.5.2
			--Description: Check TTS wrong response with correct HMI correlation id
			
				function Test:ResetGlobalProperties_TTS_WrongResponse_WithCorrectHMICorrelationId()
				
					--mobile side: sending ResetGlobalProperties request
					local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
					{
						properties = 
						{
							"VRHELPTITLE",
							"MENUNAME",
							"MENUICON",
							"KEYBOARDPROPERTIES",
							"VRHELPITEMS",
							"HELPPROMPT",
							"TIMEOUTPROMPT"
						}
					})
				

					--hmi side: expect TTS.SetGlobalProperties request
					EXPECT_HMICALL("TTS.SetGlobalProperties", {})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						self.hmiConnection:SendResponse(data.id, "TTS.Speak", "SUCCESS", {})
					end)

				

					--hmi side: expect UI.SetGlobalProperties request
					EXPECT_HMICALL("UI.SetGlobalProperties", {})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)

				

					--mobile side: expect ResetGlobalProperties response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
					:Timeout(12000)

					EXPECT_NOTIFICATION("OnHashChange")
					:Timeout(12000)
					:Times(0)					
				end

			--End Test case HMINegativeCheck.5.2
		--End Test suit HMINegativeCheck.5
	--End Test suit HMINegativeCheck
]]
----------------------------------------------------------------------------------------------
-----------------------------------------VI TEST BLOCK----------------------------------------
-------------------------Sequence with emulating of user's action(s)--------------------------
----------------------------------------------------------------------------------------------

	--Begin Test suit SequenceCheck
	--Description: TC's checks SDL behavior by processing
		-- different request sequence with timeout
		-- with emulating of user's actions

		
		--Begin Test suit SequenceCheck.1
		--Description: check scenario in test case TC_ResetGlobalProperties_01: request with all parameters from mobile

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-18

			--Verification criteria: ResetGlobalProperties request resets the requested GlobalProperty values to default ones.

			function Test:TC_ResetGlobalProperties_01_ResetGlobalProperties_WithAllParameter()
			
				--mobile side: sending ResetGlobalProperties request
				local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
				{
					properties = 
					{
						"VRHELPTITLE",
						"VRHELPITEMS",
						"HELPPROMPT",
						"TIMEOUTPROMPT"
					}
				})
				--hmi side: expect TTS.SetGlobalProperties request
				EXPECT_HMICALL("TTS.SetGlobalProperties",
				{
					--[=[ TODO: update after resolving APPLINK-9734
					helpPrompt = 
					{
						{
							type = "TEXT",
							text = textPromtValue[1]
						},
						{
							type = "TEXT",
							text = textPromtValue[2]
						}
					},]=]
					timeoutPrompt = 
					{
						{
							type = "TEXT",
							text = "Please speak one of the following commands,"
						},
						{
							type = "TEXT",
							text = "Please say a command,"
						}
					}
				})
				:Timeout(iTimeout)
				:Do(function(_,data)
					--hmi side: sending TTS.SetGlobalProperties response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)

			

				--hmi side: expect UI.SetGlobalProperties request
				EXPECT_HMICALL("UI.SetGlobalProperties",
				{
					vrHelpTitle = "Test Application",
				})
				
				:Timeout(iTimeout)
				:Do(function(_,data)
					--hmi side: sending UI.SetGlobalProperties response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)

			

				--mobile side: expect SetGlobalProperties response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
				:Timeout(iTimeout)
				
				EXPECT_NOTIFICATION("OnHashChange")
				:Timeout(iTimeout)
			end

		--End Test case SequenceCheck.1
		-----------------------------------------------------------------------------------------	

		--Begin Test suit SequenceCheck.2
		--Description: check scenario in test case TC_ResetGlobalProperties_02: 
			--Step 1: Execute ResetGlobalProperties

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-18

			--Verification criteria: ResetGlobalProperties request resets the requested GlobalProperty values to default ones.

			function Test:TC_ResetGlobalProperties_02_Step1_ResetGlobalProperties_With_VRHELPTITLE_Parameter()
				
				result = true
				--mobile side: sending ResetGlobalProperties request
				local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
				{
					properties = 
					{
						"VRHELPTITLE"
					}
				})
							

				--hmi side: expect UI.SetGlobalProperties request
				EXPECT_HMICALL("UI.SetGlobalProperties",
				{
					vrHelpTitle = "Test Application",
					appID = self.applications["Test Application"]
				})
				
				:Timeout(iTimeout)
				:Do(function(_,data)
					--hmi side: sending UI.SetGlobalProperties response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)
				:ValidIf(function(_,data)
					--UPDATED according to APPLINK20718
					if (data.params.vrHelp[1].position ~= 1) then
						print(" \27[36m UI.SetGlobalProperties: vrHelp[1].position: Expected: 1; Real: " .. data.params.vrHelp[1].position .. "  \27[0m ")
						result = false
					end

					if (data.params.vrHelp[1].text ~= "VRCommand1") then
						print(" \27[36m UI.SetGlobalProperties: vrHelp[1].text: Expected: VRCommand1; Real: " .. data.params.vrHelp[1].text .. "  \27[0m ")
						result = false
					end

					if (data.params.vrHelpTitle ~= "Test Application") then 
						print(" \27[36m UI.SetGlobalProperties: vrHelpTitle: Expected: Test Application; Real: " .. data.params.vrHelpTitle .. "  \27[0m ")
						result = false
					end

					return result
				end)

			

				--mobile side: expect SetGlobalProperties response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
				:Timeout(iTimeout)
				
				EXPECT_NOTIFICATION("OnHashChange")
				:Timeout(iTimeout)
			end

		--End Test case SequenceCheck.2
		-----------------------------------------------------------------------------------------

		--Begin Test suit SequenceCheck.3
		--Description: check scenario in test case TC_ResetGlobalProperties_02: 
			--Step 2: Execute SetGlobalProperties request

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-18

			--Verification criteria: SetGlobalProperties request sets the requested GlobalProperty values for VrHelp and VrHelpTitle
			
			--Precondition: Put file "action.png" again
			function Test:Putfile_action_png()
				--mobile side: sending PutFile request
				local cid = self.mobileSession:SendRPC("PutFile",
														{
															syncFileName = "action.png",
															fileType	= "GRAPHIC_PNG",
															persistentFile = false,
															systemFile = false
														},
														"files/action.png")

				--mobile side: expect PutFile response
				EXPECT_RESPONSE(cid, { success = true})

			end
			
			function Test:TC_ResetGlobalProperties_02_Step2_SetGlobalProperties()
			
				--mobile side: sending SetGlobalProperties request
				local cid = self.mobileSession:SendRPC("SetGlobalProperties",
				{
					vrHelp = 
					{
						{
							position = 1,
							image = 
							{
								value = "action.png",
								imageType = "DYNAMIC"
							},
							text = "VR help item"
						}
					},
					vrHelpTitle = "VR help title"
				})
			
				--hmi side: expect UI.SetGlobalProperties request
				EXPECT_HMICALL("UI.SetGlobalProperties",
				{
					vrHelp = 
					{
						{
							position = 1,
							--[=[ TODO: update after resolving APPLINK-16052
							image = 
							{
								imageType = "DYNAMIC",
								value = strAppFolder .. "action.png"
							},]=]
							text = "VR help item"
						}
					},
					vrHelpTitle = "VR help title"
				})
				:Timeout(iTimeout)
				:Do(function(_,data)
					--hmi side: sending UI.SetGlobalProperties response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)

			

				--mobile side: expect SetGlobalProperties response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
				:Timeout(iTimeout)

				EXPECT_NOTIFICATION("OnHashChange")
				:Timeout(iTimeout)				
			end
		--End Test case SequenceCheck.3
		-----------------------------------------------------------------------------------------	

		--Begin Test suit SequenceCheck.4
		--Description: check scenario in test case TC_ResetGlobalProperties_02: 
			--Step 3: Execute ResetGlobalProperties

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-18

			--Verification criteria: ResetGlobalProperties request resets the requested GlobalProperty values to default ones.
			
			function Test:TC_ResetGlobalProperties_02_Step3_ResetGlobalProperties_With_VRHELPTITLE_Parameter_Again()
				
				--mobile side: sending ResetGlobalProperties request
				local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
				{
					properties = 
					{
						"VRHELPTITLE"
					}
				})
							

				--hmi side: expect UI.SetGlobalProperties request
				EXPECT_HMICALL("UI.SetGlobalProperties",
				{
					vrHelpTitle = "Test Application",
				})
				
				:Timeout(iTimeout)
				:Do(function(_,data)
					--hmi side: sending UI.SetGlobalProperties response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)

			

				--mobile side: expect SetGlobalProperties response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
				:Timeout(iTimeout)
				
				EXPECT_NOTIFICATION("OnHashChange")
				:Timeout(iTimeout)
			end


		--End Test case SequenceCheck.4
		-----------------------------------------------------------------------------------------	

		
	--End Test suit SequenceCheck
	
----------------------------------------------------------------------------------------------
-----------------------------------------VII TEST BLOCK---------------------------------------
--------------------------------------Different HMIStatus-------------------------------------
----------------------------------------------------------------------------------------------
	--Description: processing of request/response in different HMIlevels, SystemContext, AudioStreamingState

	--Begin Test suit DifferentHMIlevel
	--Description: processing API in different HMILevel
			
		--Begin Test case DifferentHMIlevel.1
		--Description: Check ResetGlobalProperties in LIMITED HMI level

			--Requirement id in JAMA: SDLAQ-CRS-765

			--Verification criteria: SDL returns SUCCESS
			
			if commonFunctions:isMediaApp() then
				
				-- Precondition: Change app to LIMITED
				commonSteps:ChangeHMIToLimited()	
				
				function Test:ResetGlobalProperties_LIMITED()
				
					--mobile side: sending ResetGlobalProperties request
					local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
					{
						properties = 
						{
							"VRHELPTITLE",
							"MENUNAME",
							"MENUICON",
							"KEYBOARDPROPERTIES",
							"VRHELPITEMS",
							"HELPPROMPT",
							"TIMEOUTPROMPT"
						}
					})
					--hmi side: expect TTS.SetGlobalProperties request
					EXPECT_HMICALL("TTS.SetGlobalProperties",
					{
						--[=[ TODO: update after resolving APPLINK-9734
						helpPrompt = 
						{
							{
								type = "TEXT",
								text = textPromtValue[1]
							},
							{
								type = "TEXT",
								text = textPromtValue[2]
							}
						},]=]
						timeoutPrompt = 
						{
							{
								type = "TEXT",
								text = "Please speak one of the following commands,"
							},
							{
								type = "TEXT",
								text = "Please say a command,"
							}
						}
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending TTS.SetGlobalProperties response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)

				

					--hmi side: expect UI.SetGlobalProperties request
					EXPECT_HMICALL("UI.SetGlobalProperties",
					{
						menuTitle = title_to_check,
						menuIcon = {
										imageType = "DYNAMIC",
										value = icon_to_check
									},
						vrHelpTitle = "Test Application",
						keyboardProperties = 
						{
							keyboardLayout = "QWERTY",
							autoCompleteText = "",
							language = "EN-US"
						},
						vrHelp = nil
					})
					
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)

				

					--mobile side: expect SetGlobalProperties response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
					:Timeout(iTimeout)
						
					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")
				end
			end
			
		--End Test case DifferentHMIlevel.1
		-----------------------------------------------------------------------------------------
		
		
		--Begin Test case DifferentHMIlevel.2
		--Description: Check ResetGlobalProperties in BACKGOUND HMI level

			--Requirement id in JAMA: SDLAQ-CRS-765

			--Verification criteria: SDL returns SUCCESS
			
			-- Precondition 1: Change app to BACKGOUND HMI level
			commonTestCases:ChangeAppToBackgroundHmiLevel()
		
			function Test:ResetGlobalProperties_BACKGROUND()
			
				--mobile side: sending ResetGlobalProperties request
				local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
				{
					properties = 
					{
						"VRHELPTITLE",
						"MENUNAME",
						"MENUICON",
						"KEYBOARDPROPERTIES",
						"VRHELPITEMS",
						"HELPPROMPT",
						"TIMEOUTPROMPT"
					}
				})
				--hmi side: expect TTS.SetGlobalProperties request
				EXPECT_HMICALL("TTS.SetGlobalProperties",
				{
					--[=[ TODO: update after resolving APPLINK-9734
					helpPrompt = 
					{
						{
							type = "TEXT",
							text = textPromtValue[1]
						},
						{
							type = "TEXT",
							text = textPromtValue[2]
						}

					},]=]
					timeoutPrompt = 
					{
						{
							type = "TEXT",
							text = "Please speak one of the following commands,"
						},
						{
							type = "TEXT",
							text = "Please say a command,"
						}
					}
				})
				:Timeout(iTimeout)
				:Do(function(_,data)
					--hmi side: sending TTS.SetGlobalProperties response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)

			

				--hmi side: expect UI.SetGlobalProperties request
				EXPECT_HMICALL("UI.SetGlobalProperties",
				{
					menuTitle = title_to_check,
					menuIcon = {
									imageType = "DYNAMIC",
									value = icon_to_check
								},
					vrHelpTitle = "Test Application",
					keyboardProperties = 
					{
						keyboardLayout = "QWERTY",
						autoCompleteText = "",
						language = "EN-US"
					},
					vrHelp = nil

				})
				
				:Timeout(iTimeout)
				:Do(function(_,data)
					--hmi side: sending UI.SetGlobalProperties response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)

			

				--mobile side: expect SetGlobalProperties response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
				:Timeout(iTimeout)
						
				--mobile side: expect OnHashChange notification
				EXPECT_NOTIFICATION("OnHashChange")
			end

		--End Test case DifferentHMIlevel.2
	--End Test suit DifferentHMIlevel

-----------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
-------------------------------------------Postconditions-------------------------------------
---------------------------------------------------------------------------------------------

		function Test:RemoveConfigurationFiles()    
    		commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
		end
			
return Test

