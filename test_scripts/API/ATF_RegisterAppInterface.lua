--------------------------------------------------------------------------------
-- Preconditions
--------------------------------------------------------------------------------
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
--------------------------------------------------------------------------------
--Precondition: preparation connecttest_RAI.lua
commonPreconditions:Connecttest_without_ExitBySDLDisconnect("connecttest_RAI.lua")

--ToDo: shall be removed when APPLINK-16610 is fixed
config.defaultProtocolVersion = 2

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

Test = require('user_modules/connecttest_RAI')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local commonPreconditions = require ('/user_modules/shared_testcases/commonPreconditions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local srcPath = config.pathToSDL .. "sdl_preloaded_pt.json"
local dstPath = config.pathToSDL .. "sdl_preloaded_pt.json.origin"

----------------------------------------------------------------------------
-- User required files
require('user_modules/AppTypes')

local hmi_connection = require('hmi_connection')
local websocket      = require('websocket_connection')
local module         = require('testbase')
local mobile  = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')

----------------------------------------------------------------------------
-- User variables, arrays
local audibleState

----------------------------------------------------------------------------
-- User functions

function DelayedExp(time)
  local event = events.Event()
  event.matches = function(self, e) return self == e end
  EXPECT_EVENT(event, "Delayed event")
  	:Timeout(time+1000)
  RUN_AFTER(function()
              RAISE_EVENT(event, event)
            end, time)
end

local function OpenConnectionCreateSession(self)
	local tcpConnection = tcp.Connection(config.mobileHost, config.mobilePort)
	local fileConnection = file_connection.FileConnection("mobile.out", tcpConnection)
	self.mobileConnection = mobile.MobileConnection(fileConnection)
	self.mobileSession= mobile_session.MobileSession(
	self,
	self.mobileConnection)
	event_dispatcher:AddConnection(self.mobileConnection)
	self.mobileSession:ExpectEvent(events.connectedEvent, "Connection started")
	self.mobileConnection:Connect()
	self.mobileSession:StartService(7)
end

local function UnregisterApplicationSessionOne(self)
	--mobile side: UnregisterAppInterface request 
	local CorIdUAI = self.mobileSession:SendRPC("UnregisterAppInterface",{}) 

	--hmi side: expect OnAppUnregistered notification 
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.applications["SyncProxyTester"], unexpectedDisconnect = false})
 

	 --mobile side: UnregisterAppInterface response 
	EXPECT_RESPONSE(CorIdUAI, { success = true, resultCode = "SUCCESS"})
		:Timeout(2000) 
end

local function UnregisteerApplicationSessionTwo(self)
	--mobile side: UnregisterAppInterface request 
	local CorIdUAI = self.mobileSession1:SendRPC("UnregisterAppInterface",{}) 

	--hmi side: expect OnAppUnregistered notification 
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.appID2, unexpectedDisconnect = false})
 

	 --mobile side: UnregisterAppInterface response 
	self.mobileSession1:ExpectResponse(CorIdUAI, { success = true, resultCode = "SUCCESS"})
		:Timeout(2000) 
end

if 
	Test.isMediaApplication == true or
	Test.appHMITypes["COMMUNICATION"] == true or
	Test.appHMITypes["NAVIGATION"] == true then
		audibleState = "AUDIBLE"
else
	audibleState = "NOT_AUDIBLE"
end

--Check pathToSDL, in case last symbol is not'/' add '/' 
local function checkSDLPathValue()
	findresult = string.find (config.pathToSDL, '.$')

	if string.sub(config.pathToSDL,findresult) ~= "/" then
		config.pathToSDL = config.pathToSDL..tostring("/")
	end 
end

local function userPrint( color, message)
  print ("\27[" .. tostring(color) .. "m " .. tostring(message) .. " \27[0m")
end

-- Stop SDL, optionaly changing values of SupportedDiagModes, start SDL, HMI initialization, create mobile connection
local function RestartSDLChangingSupportedDiagModesValue(self, prefix,  SupportedDiagModes , GetSystemInfoParams, SDLVersion)

	checkSDLPathValue()

	SDLStoragePath = config.pathToSDL .. "storage/"

	local SDLini = config.pathToSDL .. tostring("smartDeviceLink.ini")

	Test["StopSDL_" .. tostring(prefix)] = function(self)
		StopSDL()
	end

	if SupportedDiagModes then
		Test["Precondition_SetSupportedDiagModesInIniFile_" .. tostring(prefix)] = function(self)
			local StringToReplace = "SupportedDiagModes = " .. tostring(SupportedDiagModes) .. "\n"
			f = assert(io.open(SDLini, "r"))
			if f then
				fileContent = f:read("*all")
					local MatchResult = string.match(fileContent, "SupportedDiagModes%s-=[%w%s,]*\n")
					if MatchResult ~= nil then
						fileContentUpdated  =  string.gsub(fileContent, MatchResult, StringToReplace)
						f = assert(io.open(SDLini, "w"))
						f:write(fileContentUpdated)
					else 
						userPrint(31, "Finding of 'SupportedDiagModes = value' is failed. Expect string finding and replacing of value to true")
					end
				f:close()
			end
		end
	end

	if SDLVersion then
		Test["Precondition_SetSDLVersionInIniFile_" .. tostring(prefix)] = function(self)
			local StringToReplace = "SDLVersion = " .. tostring(SDLVersion) .. "\n"
			f = assert(io.open(SDLini, "r"))
			if f then
				fileContent = f:read("*all")
				if SDLVersion == ";" then
					fileContentUpdated  =  string.gsub(fileContent, "%p?SDLVersion%s-=[%w%s%p]-\n", ";SDLVersion = version \n")
				else
					fileContentUpdated  =  string.gsub(fileContent, "%p?SDLVersion%s-=[%w%s%p]-\n", StringToReplace)
				end

				if fileContentUpdated then
					f = assert(io.open(SDLini, "w"))
					f:write(fileContentUpdated)
				else 
					userPrint(31, "Finding of 'SDLVersion = value' is failed. Expect string finding and replacing of value to true")
				end
				f:close()
			end
		end
	end 

	Test["StartSDL_" .. tostring(prefix)] = function(self)
		StartSDL(config.pathToSDL, config.ExitOnCrash)
	end

	Test["InitHMI_" .. tostring(prefix)] = function(self)
		self:initHMI()
	end

	Test["InitHMIonReady_" .. tostring(prefix)] = function(self)
		self:initHMI_onReady()

		if GetSystemInfoParams then
			EXPECT_HMICALL("BasicCommunication.GetSystemInfo")
			:Do(function(_,data)
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", GetSystemInfoParams)
			end)
		end
	end

	Test["ConnectMobile_" .. tostring(prefix)] = function(self)
		self:connectMobile()
	end

	Test["StartSession_" .. tostring(prefix)] = function(self)
		self.mobileSession= mobile_session.MobileSession(
		    self,
		    self.mobileConnection)

	    self.mobileSession:StartService(7)
	end
end

--App registration 
local function AppRegistration(self, registerParams, SupportedDiagModesValue)

    local CorIdRegister = self.mobileSession:SendRPC("RegisterAppInterface", registerParams)

    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
   	{
      application = {appName = registerParams.appName}
    })
    :Do(function(_,data)
        self.applications[registerParams.appName] = data.params.application.appID
    end)


    self.mobileSession:ExpectResponse(CorIdRegister, 
    	{ 
    		success = true, 
    		resultCode = "SUCCESS",
    		supportedDiagModes = SupportedDiagModesValue
    	})
	    :ValidIf(function(_,data)
	    	if SupportedDiagModesValue == nil then
	    		if data.payload.supportedDiagModes then
	    			userPrint(31, "RAI response contains supportedDiagModes parameter with value ")
	    			print_table(data.payload.supportedDiagModes)
	    			return false
	    		else
	    			return true
	    		end
	    	else 
	    		return true
	    	end
	    end)

	EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

end

--App registration
local function RegisterApp(self, registerParams, ResponseParams)
	local CorIdRegister = self.mobileSession:SendRPC("RegisterAppInterface", registerParams)

    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
   	{
      application = {appName = registerParams.appName}
    })
    :Do(function(_,data)
        self.applications[registerParams.appName] = data.params.application.appID
    end)


    self.mobileSession:ExpectResponse(CorIdRegister, ResponseParams)

	EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
end

-- copy table
function copy_table(t)
  local t2 = {}
  for k,v in pairs(t) do
    t2[k] = v
  end
  return t2
end

-- copy register parameters from config.lua to local variable
local RAIParams = copy_table(config.application1.registerAppInterfaceParams)

AppMediaType = RAIParams.isMediaApplication

---------------------------------------------------------------------------------------------
------------------------- General Precondition before ATF start -----------------------------
---------------------------------------------------------------------------------------------
--make backup copy of file sdl_preloaded_pt.json
commonPreconditions:BackupFile("sdl_preloaded_pt.json")
-- TODO: Remove after implementation policy update
-- Precondition: remove policy table
commonSteps:DeletePolicyTable()

-- TODO: Remove after implementation policy update
-- Precondition: replace preloaded file with new one
os.execute('cp ./files/ptu_RAI.json ' .. tostring(config.pathToSDL) .. "sdl_preloaded_pt.json")

-- Removing user_modules/connecttest_RAI.lua after SDL start
function Test:Precondition_remove_user_connecttest()
 	os.execute( "rm -f ./user_modules/connecttest_RAI.lua" )
end


---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------

	--Begin Precondition.1
	--Description: Activation of application
	
	function Test:ActivationApp()

		--hmi side: sending SDL.ActivateApp request
	  	local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"]})

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
	    			  	--TODO: Update after resolving APPLINK-16094 EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
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
	  	EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = audibleState})	

	end

	--End Precondition.1

	--Begin Precondition.2
	--Description: Policy update for RegisterAppInterface API
	--TODO: Remove after implementation policy update 
	-- function Test:Postcondition_PolicyUpdateRAI()

	-- 	--hmi side: sending SDL.GetURLS request
	-- 	local RequestIdGetURLS = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
		
	-- 	--hmi side: expect SDL.GetURLS response from HMI
	-- 	EXPECT_HMIRESPONSE(RequestIdGetURLS,{result = {code = 0, method = "SDL.GetURLS", urls = {{url = "http://policies.telematics.ford.com/api/policies"}}}})
	-- 	:Do(function(_,data)
	-- 		--print("SDL.GetURLS response is received")
	-- 		--hmi side: sending BasicCommunication.OnSystemRequest request to SDL
	-- 		self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
	-- 			{
	-- 				requestType = "PROPRIETARY",
	-- 				fileName = "filename"
	-- 			}
	-- 		)
	-- 		--mobile side: expect OnSystemRequest notification 
	-- 		EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY" })
	-- 		:Do(function(_,data)
	-- 			--print("OnSystemRequest notification is received")
	-- 			--mobile side: sending SystemRequest request 
	-- 			local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
	-- 				{
	-- 					fileName = "PolicyTableUpdate",
	-- 					requestType = "PROPRIETARY"
	-- 				},
	-- 			"files/ptu_RAI.json")
				
	-- 			local systemRequestId
	-- 			--hmi side: expect SystemRequest request
	-- 			EXPECT_HMICALL("BasicCommunication.SystemRequest")
	-- 			:Do(function(_,data)
	-- 				systemRequestId = data.id
	-- 				--print("BasicCommunication.SystemRequest is received")
					
	-- 				--hmi side: sending BasicCommunication.OnSystemRequest request to SDL
	-- 				self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
	-- 					{
	-- 						policyfile = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate"
	-- 					}
	-- 				)
	-- 				function to_run()
	-- 					--hmi side: sending SystemRequest response
	-- 					self.hmiConnection:SendResponse(systemRequestId,"BasicCommunication.SystemRequest", "SUCCESS", {})
	-- 				end
					
	-- 				RUN_AFTER(to_run, 500)
	-- 			end)
				
	-- 			--hmi side: expect SDL.OnStatusUpdate
	-- 			EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate")
	-- 			:ValidIf(function(exp,data)
	-- 				if 
	-- 					exp.occurences == 1 and
	-- 					data.params.status == "UP_TO_DATE" then
	-- 						return true
	-- 				elseif
	-- 					exp.occurences == 1 and
	-- 					data.params.status == "UPDATING" then
	-- 						return true
	-- 				elseif
	-- 					exp.occurences == 2 and
	-- 					data.params.status == "UP_TO_DATE" then
	-- 						return true
	-- 				else 
	-- 					if 
	-- 						exp.occurences == 1 then
	-- 							print ("\27[31m SDL.OnStatusUpdate came with wrong values. Expected in first occurrences status 'UP_TO_DATE' or 'UPDATING', got '" .. tostring(data.params.status) .. "' \27[0m")
	-- 					elseif exp.occurences == 2 then
	-- 							print ("\27[31m SDL.OnStatusUpdate came with wrong values. Expected in second occurrences status 'UP_TO_DATE', got '" .. tostring(data.params.status) .. "' \27[0m")
	-- 					end
	-- 					return false
	-- 				end
	-- 			end)
	-- 			:Times(Between(1,2))
				
	-- 			--mobile side: expect SystemRequest response
	-- 			EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
	-- 			:Do(function(_,data)
	-- 				--print("SystemRequest is received")
	-- 				--hmi side: sending SDL.GetUserFriendlyMessage request to SDL
	-- 				local RequestIdGetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"StatusUpToDate"}})
					
	-- 				--hmi side: expect SDL.GetUserFriendlyMessage response
	-- 				-- TODO: update after resolving APPLINK-16094 EXPECT_HMIRESPONSE(RequestIdGetUserFriendlyMessage,{result = {code = 0, method = "SDL.GetUserFriendlyMessage", messages = {{line1 = "Up-To-Date", messageCode = "StatusUpToDate", textBody = "Up-To-Date"}}}})
	-- 				EXPECT_HMIRESPONSE(RequestIdGetUserFriendlyMessage)
	-- 				:Do(function(_,data)
	-- 					print("SDL.GetUserFriendlyMessage is received")			
	-- 				end)
	-- 			end)
				
	-- 		end)
	-- 	end)
	-- end	
	--End Precondition.2

	--Begin Precondition.3
	--Description: The application should be unregistered before next test.

		function Test:UnregisterAppInterface_Success_WithConditionalParams() 

			UnregisterApplicationSessionOne(self)

		end

	--End Precondition.3




---------------------------------------------------------------------------------------------
-----------------------------------------I TEST BLOCK----------------------------------------
--------------------------------------CommonRequestCheck: Check of mandatory/conditional request's parameters (mobile protocol)-----------------------------------
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
			--Description: Check processing request with or without conditional parameters

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-3, SDLAQ-CRS-1316,SDLAQ-CRS-1317,SDLAQ-CRS-2753, SDLAQ-CRS-197

			--Verification criteria: The request for registering was sent and executed successfully. The response code SUCCESS is returned.
			--When the app is registered with RegisterAppInterface, the corresponding request, response and notification are sent to mobile side in the following order: RegisterAppInterface request, RegisterAppInterface response, OnHMIStatus and OnPermissionsChnage notifications (the order of these two notifications is may vary, but they come AFTER RegisterAppInterface(response)).

			--Begin Test case CommonRequestCheck.1.1
			--Description: Check processing request with app parameters

				function Test:RegisterAppInterface_WithConditionalParams() 
					
					--mobile side: RegisterAppInterface request 
					local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																{
																  	 
																	syncMsgVersion = 
																	{ 
																		majorVersion = 2,
																		minorVersion = 2,
																	}, 
																	appName ="SyncProxyTester",
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
																		"VRSyncProxyTester",
																	}, 
																	isMediaApplication = AppMediaType,
																	languageDesired ="EN-US",
																	hmiDisplayLanguageDesired ="EN-US",
																	appHMIType = 
																	{ 
																		"DEFAULT",
																	}, 
																	appID ="123456",
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
						                	appName = "SyncProxyTester",
						                	ngnMediaScreenAppName ="SPT",
						                	--[=[TODO: update after resolving APPLINK-16052

						                	deviceInfo = 
											{
												name = "127.0.0.1",
												id = config.deviceMAC,
												transportType = "WIFI",
												isSDLAllowed = true
											},]=]
											policyAppID = "123456",
											hmiDisplayLanguageDesired ="EN-US",
											isMediaApplication = AppMediaType,
											appType = 
											{ 
												"DEFAULT"
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
											"VRSyncProxyTester",
										}
						            })

					--mobile side: RegisterAppInterface response 
					EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
						:Timeout(2000)
						:Do(function(_,data)

							EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

						end)


					EXPECT_NOTIFICATION("OnPermissionsChange")

				end
			--End Test case CommonRequestCheck.1.1

			--Begin Test case CommonRequestCheck.1.2
			--Description:  Without conditional parameters (only mandatory)

				-- Precondition: The application should be unregistered before next test.

				function Test:UnregisterAppInterface_Success_OnlyMandatory() 

					UnregisterApplicationSessionOne(self)

				end

				function Test:RegisterAppInterface_OnlyMandatory() 
					--mobile side: RegisterAppInterface request 
					local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																{
																  	 
																	syncMsgVersion = 
																	{ 
																		majorVersion = 2,
																		minorVersion = 2,
																	}, 
																	appName ="SyncProxyTester",
																	isMediaApplication = AppMediaType,
																	languageDesired ="EN-US",
																	hmiDisplayLanguageDesired ="EN-US",
																	appID ="123456",
																
																})

					--hmi side: expected  BasicCommunication.OnAppRegistered
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
						            {
						              	application = 
						              	{
						                	appName = "SyncProxyTester",
											policyAppID = "123456",
											hmiDisplayLanguageDesired ="EN-US",
											isMediaApplication = AppMediaType
						              	}
						            })

					--mobile side: RegisterAppInterface response 
					EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
						:Timeout(2000)

					EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

				end

			--End Test case CommonRequestCheck.1.2

			--Begin Test case CommonRequestCheck.1.3
			--Description:  With conditional ttsName parameter

				-- Precondition: The application should be unregistered before next test.

				function Test:UnregisterAppInterface_Success_ttsNameConditional() 
					UnregisterApplicationSessionOne(self)
				end

				function Test:RegisterAppInterface_ttsNameConditional() 
					--mobile side: RegisterAppInterface request 
					local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																{
																  	 
																	syncMsgVersion = 
																	{ 
																		majorVersion = 2,
																		minorVersion = 2,
																	}, 
																	appName ="SyncProxyTester",
																	isMediaApplication = AppMediaType,
																	languageDesired ="EN-US",
																	hmiDisplayLanguageDesired ="EN-US",
																	appID ="123456",
																	ttsName = 
																	{ 
																		{ 
																			text ="SyncProxyTester",
																			type ="TEXT",
																		}, 
																	}
																
																})

					--hmi side: expected  BasicCommunication.OnAppRegistered
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
						            {
						              	application = 
						              	{
						                	appName = "SyncProxyTester",
											policyAppID = "123456",
											hmiDisplayLanguageDesired ="EN-US",
											isMediaApplication = AppMediaType
						              	},
						              	ttsName = 
										{ 
											{ 
												text ="SyncProxyTester",
												type ="TEXT",
											}, 
										}
						            })

					--mobile side: RegisterAppInterface response 
					EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
						:Timeout(2000)

					EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

				end

			--End Test case CommonRequestCheck.1.3

			--Begin Test case CommonRequestCheck.1.4
			--Description:  With conditional ngnMediaScreenAppName parameter

				-- Precondition: The application should be unregistered before next test.

				function Test:UnregisterAppInterface_Success_ngnMediaScreenAppNameConditional() 

					UnregisterApplicationSessionOne(self)
				end

				function Test:RegisterAppInterface_ngnMediaScreenAppNameConditional() 
					--mobile side: RegisterAppInterface request 
					local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																{
																  	 
																	syncMsgVersion = 
																	{ 
																		majorVersion = 2,
																		minorVersion = 2,
																	}, 
																	appName ="SyncProxyTester",
																	isMediaApplication = AppMediaType,
																	languageDesired ="EN-US",
																	hmiDisplayLanguageDesired ="EN-US",
																	appID ="123456",
																	ngnMediaScreenAppName ="SPT",
																
																})

					--hmi side: expected  BasicCommunication.OnAppRegistered
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
						            {
						              	application = 
						              	{
						                	appName = "SyncProxyTester",
											policyAppID = "123456",
											hmiDisplayLanguageDesired ="EN-US",
											isMediaApplication = AppMediaType,
											ngnMediaScreenAppName ="SPT"
						              	}
						            })

					--mobile side: RegisterAppInterface response 
					EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
						:Timeout(2000)

					EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

				end

			--End Test case CommonRequestCheck.1.4

			--Begin Test case CommonRequestCheck.1.5
			--Description:  With conditional vrSynonyms parameter

				-- Precondition: The application should be unregistered before next test.

				function Test:UnregisterAppInterface_Success_vrSynonymsConditional() 

					UnregisterApplicationSessionOne(self)
				end

				function Test:RegisterAppInterface_vrSynonymsConditional() 
					--mobile side: RegisterAppInterface request 
					local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																{
																  	 
																	syncMsgVersion = 
																	{ 
																		majorVersion = 2,
																		minorVersion = 2,
																	}, 
																	appName ="SyncProxyTester",
																	isMediaApplication = AppMediaType,
																	languageDesired ="EN-US",
																	hmiDisplayLanguageDesired ="EN-US",
																	appID ="123456",
																	vrSynonyms = 
																	{ 
																		"VRSyncProxyTester",
																	}
																
																})

					--hmi side: expected  BasicCommunication.OnAppRegistered
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
						            {
						              	application = 
						              	{
						                	appName = "SyncProxyTester",
											policyAppID = "123456",
											hmiDisplayLanguageDesired ="EN-US",
											isMediaApplication = AppMediaType
						              	},
						              	vrSynonyms = 
						              	{ 
											"VRSyncProxyTester",
										}
						            })

					--mobile side: RegisterAppInterface response 
					EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
						:Timeout(2000)

					EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

				end

			--End Test case CommonRequestCheck.1.5

			--Begin Test case CommonRequestCheck.1.6
			--Description:  With conditional appHMIType parameter

				-- Precondition: The application should be unregistered before next test.

				function Test:UnregisterAppInterface_Success_appHMITypeConditional() 

					UnregisterApplicationSessionOne(self)
				end

				function Test:RegisterAppInterface_appHMITypeConditional() 
					--mobile side: RegisterAppInterface request 
					local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																{
																  	 
																	syncMsgVersion = 
																	{ 
																		majorVersion = 2,
																		minorVersion = 2,
																	}, 
																	appName ="SyncProxyTester",
																	isMediaApplication = AppMediaType,
																	languageDesired ="EN-US",
																	hmiDisplayLanguageDesired ="EN-US",
																	appID ="123456",
																	appHMIType = 
																	{ 
																		"DEFAULT",
																	}
																
																})

					--hmi side: expected  BasicCommunication.OnAppRegistered
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
						            {
						              	application = 
						              	{
						                	appName = "SyncProxyTester",
											policyAppID = "123456",
											hmiDisplayLanguageDesired ="EN-US",
											isMediaApplication = AppMediaType,
											appType = 
											{ 
												"DEFAULT"
											}
						              	}
						            })

					--mobile side: RegisterAppInterface response 
					EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
						:Timeout(2000)

					EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

				end

			--End Test case CommonRequestCheck.1.6

			--Begin Test case CommonRequestCheck.1.7
			--Description:  With conditional hashID parameter

				-- Precondition: The application should be unregistered before next test.

				function Test:UnregisterAppInterface_Success_hashIDConditional() 

					UnregisterApplicationSessionOne(self)
				end

				function Test:RegisterAppInterface_hashIDConditional() 
					--mobile side: RegisterAppInterface request 
					local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																{
																  	 
																	syncMsgVersion = 
																	{ 
																		majorVersion = 2,
																		minorVersion = 2,
																	}, 
																	appName ="SyncProxyTester",
																	isMediaApplication = AppMediaType,
																	languageDesired ="EN-US",
																	hmiDisplayLanguageDesired ="EN-US",
																	appID ="123456",
																	hashID = "hashID"
																})

					--hmi side: expected  BasicCommunication.OnAppRegistered
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
						            {
						              	application = 
						              	{
						                	appName = "SyncProxyTester",
											policyAppID = "123456",
											hmiDisplayLanguageDesired ="EN-US",
											isMediaApplication = AppMediaType
						              	}
						            })

					--mobile side: RegisterAppInterface response 
					EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "RESUME_FAILED"})
						:Timeout(2000)

				end

			--End Test case CommonRequestCheck.1.7

			--Begin Test case CommonRequestCheck.1.8
			--Description:  With conditional deviceInfo parameter

				-- Precondition: The application should be unregistered before next test.

				function Test:UnregisterAppInterface_Success_deviceInfoConditional()

					UnregisterApplicationSessionOne(self)
				end

				function Test:RegisterAppInterface_deviceInfoConditional() 
					--mobile side: RegisterAppInterface request 
					local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																{
																  	 
																	syncMsgVersion = 
																	{ 
																		majorVersion = 2,
																		minorVersion = 2,
																	}, 
																	appName ="SyncProxyTester",
																	isMediaApplication = AppMediaType,
																	languageDesired ="EN-US",
																	hmiDisplayLanguageDesired ="EN-US",
																	appID ="123456",
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
						                	appName = "SyncProxyTester",
											policyAppID = "123456",
											hmiDisplayLanguageDesired ="EN-US",
											isMediaApplication = AppMediaType,
											--[=[TODO: update after resolving APPLINK-16052

											deviceInfo =
											{
												name = "127.0.0.1",
												id = config.deviceMAC,
												transportType = "WIFI",
												isSDLAllowed = true
											}]=]
						              	}
						            })

					--mobile side: RegisterAppInterface response 
					EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
						:Timeout(2000)

					EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

				end

			--End Test case CommonRequestCheck.1.8

			--Begin Test case CommonRequestCheck.1.9
			--Description:  With conditional deviceInfo.hardware parameter

				-- Precondition: The application should be unregistered before next test.

				function Test:UnregisterAppInterface_Success_deviceInfohardwareConditional() 

					UnregisterApplicationSessionOne(self)
				end

				function Test:RegisterAppInterface_deviceInfohardwareConditional() 
					--mobile side: RegisterAppInterface request 
					local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																{
																  	 
																	syncMsgVersion = 
																	{ 
																		majorVersion = 2,
																		minorVersion = 2,
																	}, 
																	appName ="SyncProxyTester",
																	isMediaApplication = AppMediaType,
																	languageDesired ="EN-US",
																	hmiDisplayLanguageDesired ="EN-US",
																	appID ="123456",
																	deviceInfo = 
																	{
																		hardware = "hardware"
																	}
																})

					--hmi side: expected  BasicCommunication.OnAppRegistered
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
						            {
						              	application = 
						              	{
						                	appName = "SyncProxyTester",
											policyAppID = "123456",
											hmiDisplayLanguageDesired ="EN-US",
											isMediaApplication = AppMediaType,
											--[=[TODO: update after resolving APPLINK-16052
											deviceInfo =
											{
												name = "127.0.0.1",
												id = config.deviceMAC,
												transportType = "WIFI",
												isSDLAllowed = true
											}]=]
						              	}
						            })

					--mobile side: RegisterAppInterface response 
					EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
						:Timeout(2000)

					EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
				end

			--End Test case CommonRequestCheck.1.9

			--Begin Test case CommonRequestCheck.1.10
			--Description:  With conditional deviceInfo.firmwareRev parameter

				-- Precondition: The application should be unregistered before next test.

				function Test:UnregisterAppInterface_Success_deviceInfofirmwareRevConditional() 

					UnregisterApplicationSessionOne(self)
				end

				function Test:RegisterAppInterface_deviceInfofirmwareRevConditional() 
					--mobile side: RegisterAppInterface request 
					local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																{
																  	 
																	syncMsgVersion = 
																	{ 
																		majorVersion = 2,
																		minorVersion = 2,
																	}, 
																	appName ="SyncProxyTester",
																	isMediaApplication = AppMediaType,
																	languageDesired ="EN-US",
																	hmiDisplayLanguageDesired ="EN-US",
																	appID ="123456",
																	deviceInfo = 
																	{
																		firmwareRev = "firmwareRev"
																	}
																})

					--hmi side: expected  BasicCommunication.OnAppRegistered
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
						            {
						              	application = 
						              	{
						                	appName = "SyncProxyTester",
											policyAppID = "123456",
											hmiDisplayLanguageDesired ="EN-US",
											isMediaApplication = AppMediaType,
											--[=[TODO: update after resolving APPLINK-16052

											deviceInfo =
											{
												name = "127.0.0.1",
												id = config.deviceMAC,
												transportType = "WIFI",
												isSDLAllowed = true
											}]=]
						              	}
						            })

					--mobile side: RegisterAppInterface response 
					EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
						:Timeout(2000)

					EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
				end

			--End Test case CommonRequestCheck.1.10

			--Begin Test case CommonRequestCheck.1.11
			--Description:  With conditional deviceInfo.os parameter

				-- Precondition: The application should be unregistered before next test.

				function Test:UnregisterAppInterface_Success_deviceInfoosConditional() 

					UnregisterApplicationSessionOne(self)
				end

				function Test:RegisterAppInterface_deviceInfoosConditional() 
					--mobile side: RegisterAppInterface request 
					local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																{
																  	 
																	syncMsgVersion = 
																	{ 
																		majorVersion = 2,
																		minorVersion = 2,
																	}, 
																	appName ="SyncProxyTester",
																	isMediaApplication = AppMediaType,
																	languageDesired ="EN-US",
																	hmiDisplayLanguageDesired ="EN-US",
																	appID ="123456",
																	deviceInfo = 
																	{
																		os = "os"
																	}
																})

					--hmi side: expected  BasicCommunication.OnAppRegistered
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
						            {
						              	application = 
						              	{
						                	appName = "SyncProxyTester",
											policyAppID = "123456",
											hmiDisplayLanguageDesired ="EN-US",
											isMediaApplication = AppMediaType,
											--[=[TODO: update after resolving APPLINK-16052

											deviceInfo =
											{
												name = "127.0.0.1",
												id = config.deviceMAC,
												transportType = "WIFI",
												isSDLAllowed = true
											}]=]
						              	}
						            })

					--mobile side: RegisterAppInterface response 
					EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
						:Timeout(2000)

					EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
				end

			--End Test case CommonRequestCheck.1.11

			--Begin Test case CommonRequestCheck.1.12
			--Description:  With conditional deviceInfo.osVersion parameter

				-- Precondition: The application should be unregistered before next test.

				function Test:UnregisterAppInterface_Success_deviceInfoosVersionConditional() 

					UnregisterApplicationSessionOne(self)
				end

				function Test:RegisterAppInterface_deviceInfoosVersionConditional() 
					--mobile side: RegisterAppInterface request 
					local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																{
																  	 
																	syncMsgVersion = 
																	{ 
																		majorVersion = 2,
																		minorVersion = 2,
																	}, 
																	appName ="SyncProxyTester",
																	isMediaApplication = AppMediaType,
																	languageDesired ="EN-US",
																	hmiDisplayLanguageDesired ="EN-US",
																	appID ="123456",
																	deviceInfo = 
																	{
																		osVersion = "osVersion"
																	}
																})

					--hmi side: expected  BasicCommunication.OnAppRegistered
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
						            {
						              	application = 
						              	{
						                	appName = "SyncProxyTester",
											policyAppID = "123456",
											hmiDisplayLanguageDesired ="EN-US",
											isMediaApplication = AppMediaType,
											--[=[TODO: update after resolving APPLINK-16052

											deviceInfo =
											{
												name = "127.0.0.1",
												id = config.deviceMAC,
												transportType = "WIFI",
												isSDLAllowed = true
											}]=]
						              	}
						            })

					--mobile side: RegisterAppInterface response 
					EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
						:Timeout(2000)

					EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
				end

			--End Test case CommonRequestCheck.1.12

			--Begin Test case CommonRequestCheck.1.13
			--Description:  With conditional deviceInfo.carrier parameter

				-- Precondition: The application should be unregistered before next test.

				function Test:UnregisterAppInterface_Success_deviceInfocarrierConditional() 

					UnregisterApplicationSessionOne(self)
				end

				function Test:RegisterAppInterface_deviceInfocarrierConditional() 
					--mobile side: RegisterAppInterface request 
					local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																{
																  	 
																	syncMsgVersion = 
																	{ 
																		majorVersion = 2,
																		minorVersion = 2,
																	}, 
																	appName ="SyncProxyTester",
																	isMediaApplication = AppMediaType,
																	languageDesired ="EN-US",
																	hmiDisplayLanguageDesired ="EN-US",
																	appID ="123456",
																	deviceInfo = 
																	{
																		carrier = "carrier"
																	}
																})

					--hmi side: expected  BasicCommunication.OnAppRegistered
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
						            {
						              	application = 
						              	{
						                	appName = "SyncProxyTester",
											policyAppID = "123456",
											hmiDisplayLanguageDesired ="EN-US",
											isMediaApplication = AppMediaType,
											--[=[TODO: update after resolving APPLINK-16052

											deviceInfo =
											{
												name = "127.0.0.1",
												id = config.deviceMAC,
												transportType = "WIFI",
												isSDLAllowed = true
											}]=]
						              	}
						            })

					--mobile side: RegisterAppInterface response 
					EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
						:Timeout(2000)

					EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
				end

			--End Test case CommonRequestCheck.1.13

			--Begin Test case CommonRequestCheck.1.14
			--Description:  With conditional deviceInfo.maxNumberRFCOMMPorts parameter

				-- Precondition: The application should be unregistered before next test.

				function Test:UnregisterAppInterface_Success_deviceInfomaxNumberRFCOMMPortsConditional() 

					UnregisterApplicationSessionOne(self)
				end

				function Test:RegisterAppInterface_deviceInfomaxNumberRFCOMMPortsConditional() 
					--mobile side: RegisterAppInterface request 
					local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																{
																  	 
																	syncMsgVersion = 
																	{ 
																		majorVersion = 2,
																		minorVersion = 2,
																	}, 
																	appName ="SyncProxyTester",
																	isMediaApplication = AppMediaType,
																	languageDesired ="EN-US",
																	hmiDisplayLanguageDesired ="EN-US",
																	appID ="123456",
																	deviceInfo = 
																	{
																		maxNumberRFCOMMPorts = 5
																	}
																})

					--hmi side: expected  BasicCommunication.OnAppRegistered
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
						            {
						              	application = 
						              	{
						                	appName = "SyncProxyTester",
											policyAppID = "123456",
											hmiDisplayLanguageDesired ="EN-US",
											isMediaApplication = AppMediaType,
											--[=[TODO: update after resolving APPLINK-16052

											deviceInfo =
											{
												name = "127.0.0.1",
												id = config.deviceMAC,
												transportType = "WIFI",
												isSDLAllowed = true
											}]=]
						              	}
						            })

					--mobile side: RegisterAppInterface response 
					EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
						:Timeout(2000)

					EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
				end

			--End Test cese CommonRequestCheck.1.14


		--End Test case CommonRequestCheck.1


		--Begin Test case CommonRequestCheck.2
		--Description: This part of tests is intended to verify receiving appropriate response
			-- when request is sent with different fake parameters

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-3, SDLAQ-CRS-1316, SDLAQ-CRS-1317, SDLAQ-CRS-2753, 
				-- APPLINK-4518

			--Verification criteria:  According to xml tests by Ford team all fake params should be ignored by SDL

			--Begin Test case CommonRequestCheck.2.1
			--Description: With fake parameters (SUCCESS)

				-- Precondition: The application should be unregistered before next test.

				function Test:UnregisterAppInterface_Success_FakeParam() 

					UnregisterApplicationSessionOne(self)
				end

				function Test:RegisterAppInterface_FakeParam() 

					--mobile side: RegisterAppInterface request 
					local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																{
																  	 
																	syncMsgVersion = 
																	{ 
																		majorVersion = 2,
																		minorVersion = 2,
																		fakeParam ="fakeParam",
																	}, 
																	appName ="SyncProxyTester",
																	ttsName = 
																	{ 
																		{ 
																			text ="SyncProxyTester",
																			type ="TEXT",
																			fakeParam ="fakeParam",
																		}, 
																	}, 
																	ngnMediaScreenAppName ="SPT",
																	vrSynonyms = 
																	{ 
																		"VRSyncProxyTester",
																		fakeParam
																	}, 
																	isMediaApplication = AppMediaType,
																	languageDesired ="EN-US",
																	hmiDisplayLanguageDesired ="EN-US",
																	appHMIType = 
																	{ 
																		"DEFAULT",
																	}, 
																	appID ="123456",
																	fakeParam ="fakeParam",
																
																}) 
					--hmi side: expected  BasicCommunication.OnAppRegistered
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
					            {
					              	application = 
					              	{
					                	appName = "SyncProxyTester",
										policyAppID = "123456",
										hmiDisplayLanguageDesired ="EN-US",
										isMediaApplication = AppMediaType
					              	}
					            })
						:ValidIf(function(_,data)

							if data.params.ttsName[1].fakeParam or
								data.params.vrSynonyms[2] or
								data.params.fakeParam then
								print (" \27[36m OnAppRegistered notification came with fake parameter \27[0m")
								return false
							else 
								return true
							end

						end)
					 

					--mobile side: RegisterAppInterface response 
					EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
						:Timeout(2000)

					EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
				end

			--End Test case CommonRequestCheck.2.1

			--Begin Test case CommonRequestCheck.2.2
			--Description: Parameters from another request (SUCCESS)

				-- Precondition: The application should be unregistered before next test.
				function Test:UnregisterAppInterface_Success_ParamsAnotherReq() 
					UnregisterApplicationSessionOne(self)
				end

				function Test:RegisterAppInterface_ParamsAnotherReq() 

					--mobile side: RegisterAppInterface request 
					local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																{
																  	syncMsgVersion = 
																	{ 
																		majorVersion = 2,
																		minorVersion = 2,
																	}, 
																	appName ="SyncProxyTester",
																	isMediaApplication = AppMediaType,
																	languageDesired ="EN-US",
																	hmiDisplayLanguageDesired ="EN-US",
																	appID ="123456",
																	alertText1 ="Alert1",
																	alertText2 ="Alert1",
																	ttsChunks = 
																	{ 
																		{ 
																			text ="ThisisthefirstTTS",
																			type ="TEXT",
																		}, 
																		{ 
																			text ="ThisisthesecondTTS",
																			type ="TEXT",
																		}, 
																	}
																
																}) 
						--hmi side: expected  BasicCommunication.OnAppRegistered
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
					            {
					              	application = 
					              	{
					                	appName = "SyncProxyTester",
										policyAppID = "123456",
										hmiDisplayLanguageDesired ="EN-US",
										isMediaApplication = AppMediaType
					              	}
					            })
						:ValidIf(function(_,data)

							if data.params.alertStrings or
								data.params.ttsChunks or
								data.params.alertText1 or
								data.params.alertText2 then
								return false
							else 
								return true
							end

						end)
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
							:Timeout(2000)

						EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
				end



			--End Test case CommonRequestCheck.2.2

			--Begin Test case CommonRequestCheck.2.3
			--Description: Parameters from another request only (INVALID_DATA)

				-- Precondition: The application should be unregistered before next test.

				function Test:UnregisterAppInterface_Success_ParamsAnotherReqOnly() 

					UnregisterApplicationSessionOne(self)
				end

				function Test:RegisterAppInterface_ParamsAnotherReqOnly() 

					--mobile side: RegisterAppInterface request 
					local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																{
																  	
																	alertText1 ="Alert1",
																	alertText2 ="Alert1",
																	ttsChunks = 
																	{ 
																		{ 
																			text ="ThisisthefirstTTS",
																			type ="TEXT",
																		}, 
																		{ 
																			text ="ThisisthesecondTTS",
																			type ="TEXT",
																		}, 
																	}, 
																	duration = 5000,
																	playtone = false,
																
																}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)

				end



			--End Test case CommonRequestCheck.2.3


		--End Test case CommonRequestCheck.2

		--Begin Test case CommonRequestCheck.3
			--Description: The part of tests is intended to verify receiving INVALID_DATA response code
				-- when mandatory parameters are not provided 
				-- Mandatory parameters in RegisterAppInterface API are:
				-- - syncMsgVersion
				-- 	- major version
				-- 	- minor version
				-- - appName
				-- - isMediaApplication
				-- - languageDesired
				-- - hmiDisplayLanguageDesired
				-- - appID


				--Requirement id in JAMA: SDLAQ-CRS-3, 
					-- SDLAQ-CRS-1316

				--Verification criteria:
					--[[- The request without "syncMsgVersion" parameter is sent, the response comes with «INVALID_DATA» result code.
					- The request without "appName" parameter is sent, the response comes with «INVALID_DATA» result code.
					- The request without "isMediaApplication" parameter is sent, the response comes with «INVALID_DATA» result code.
					- The request without "languageDesired" parameter is sent, the response comes with «INVALID_DATA» result code.
					- The request without "hmiDisplayLanguageDesired" parameter is sent, the response comes with «INVALID_DATA» result code.
					- The request without "appID" parameter is sent, the response comes with «INVALID_DATA» result code.
					- The request with "languageDesired" parameter value which does'not exist in a language enum is sent, the response comes with «INVALID_DATA» result code.]]
					-- SyncMsgVersion which contains only one of the parameters (majorVersion or minorVersion) returns INVALID_DATA in the responses.

				--Begin Test case CommonRequestCheck.3.1
				--Description: syncMsgVersion is missing

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_syncMsgVersionMissing()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_syncMsgVersionMissing() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		appName ="SyncProxyTester7777777",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)

					end

				--End Test case CommonRequestCheck.3.1

				--Begin Test case CommonRequestCheck.3.2
				--Description: syncMsgVersion major version is missing

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_syncMsgVersionMajorMissing()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_syncMsgVersionMajorMissing() 

	 					--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 
						 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
								
					end

				--End Test case CommonRequestCheck.3.2

				--Begin Test case CommonRequestCheck.3.3
				--Description: syncMsgVersion minor version is missing

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_syncMsgVersionMinorMissing()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_syncMsgVersionMinorMissing() 

	 					--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																		}, 	
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case CommonRequestCheck.3.3

				--Begin Test case CommonRequestCheck.3.4
				--Description: appName is missing

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_appNameMissing()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_appNameMissing() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 
				 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case CommonRequestCheck.3.4

				--Begin Test case CommonRequestCheck.3.5
				--Description: isMediaApplication is missing

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_isMediaMissing()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_isMediaMissing() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case CommonRequestCheck.3.5

				--Begin Test case CommonRequestCheck.3.6
				--Description: languageDesired is missing

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_languageDesiredMissing()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_languageDesiredMissing() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
						{
						  	 
							syncMsgVersion = 
							{ 
								majorVersion = 2,
								minorVersion = 2,
							}, 
							appName ="SyncProxyTester",
							isMediaApplication = AppMediaType,
							hmiDisplayLanguageDesired ="EN-US",
							appID ="123456",
						
						}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case CommonRequestCheck.3.6

				--Begin Test case CommonRequestCheck.3.7
				--Description: hmiDisplayLanguageDesired is missing

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_hmiLangDesiredMissing()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_hmiLangDesiredMissing() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case CommonRequestCheck.3.7

				--Begin Test case CommonRequestCheck.3.8
				--Description: appID is missing

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_appIDMissing()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_appIDMissing() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																	
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case CommonRequestCheck.3.8

				--Begin Test case CommonRequestCheck.3.9
				--Description: All parameters are missing

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_MissingAllParams()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_MissingAllParams() 

	 					--mobile side: RegisterAppInterface request 
	   					local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",{}) 
 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case CommonRequestCheck.3.9

		--End Test case CommonRequestCheck.3

		--Begin Test case CommonRequestCheck.4
		--Description: Check processing request with invalid JSON

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-359
		
			--Verification criteria: The request with wrong JSON syntax is sent, the response comes with «INVALID_DATA» result code.

				--Precondition:  open connection and create session
				function Test:EsteblishConnectionSession_invalidJSON()
					OpenConnectionCreateSession(self)
				end

				function Test:RegisterAppInterface_invalidJSON() 

					self.mobileSession.correlationId = self.mobileSession.correlationId + 1

					--mobile side: RegisterAppInterface request 
					  local msg = 
					  {
					    serviceType      = 7,
					    frameInfo        = 0,
					    rpcType          = 0,
					    rpcFunctionId    = 1,
					    rpcCorrelationId = self.mobileSession.correlationId,
					--<<!-- missing ':'
					    payload          = '{"deviceInfo"{"osVersion":"4.4.2","os":"Android","firmwareRev":"Name: Linux, Version: 3.4.0-perf","carrier":"Megafon","maxNumberRFCOMMPorts":1},"languageDesired":"EN-US","appID":"8675308","appHMIType":["NAVIGATION"],"appName":"Test Application","syncMsgVersion":{"minorVersion":0,"majorVersion":3},"isMediaApplication":true,"hmiDisplayLanguageDesired":"EN-US"}'
					  }
					  self.mobileSession:Send(msg)
					 
					--mobile side: RegisterAppInterface response 
					EXPECT_RESPONSE("RegisterAppInterface", { success = false, resultCode = "INVALID_DATA"})
						:Timeout(2000)
				end
		

		--End Test case CommonRequestCheck.4

		--Begin Test case CommonRequestCheck.5
			--Description: Check processing requests with duplicate correlationID value
--TODO: fill Requirement, Verification criteria
				--Requirement id in JAMA/or Jira ID: 

				--Verification criteria:

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_correlationIdDuplicateValue()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_correlationIdDuplicateValue()

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																{
																  	 
																	syncMsgVersion = 
																	{ 
																		majorVersion = 2,
																		minorVersion = 2,
																	}, 
																	appName ="SyncProxyTester",
																	isMediaApplication = AppMediaType,
																	languageDesired ="EN-US",
																	hmiDisplayLanguageDesired ="EN-US",
																	appID ="123456",
																
																})

					 
						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, 
							{ success = true, resultCode = "SUCCESS"},
							{ success = false, resultCode = "APPLICATION_REGISTERED_ALREADY"})
							:Times(2)
							:Do(function(exp,data)

								if exp.occurences == 1 then

									--mobile side: RegisterAppInterface request 
									  local msg = 
									  {
									    serviceType      = 7,
									    frameInfo        = 0,
									    rpcType          = 0,
									    rpcFunctionId    = 1,
									    rpcCorrelationId = CorIdRAI,
									    payload          = '{"languageDesired":"EN-US","appID":"8675309","appHMIType":["DEFAULT"],"appName":"SyncProxyTester1","syncMsgVersion":{"minorVersion":0,"majorVersion":3},"isMediaApplication":true,"hmiDisplayLanguageDesired":"EN-US"}'
									  }
									  self.mobileSession:Send(msg)

									  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
								end

							end)

					end


		--End Test case CommonRequestCheck.5


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

			--Begin Test case PositiveRequestCheck.1
			--Description: Check processing request with values in bound and boundary conditions

				--Requirement id in JAMA: SDLAQ-CRS-3, SDLAQ-CRS-1316, SDLAQ-CRS-1317, SDLAQ-CRS-2753, SDLAQ-CRS-3044

				--Verification criteria: 
					--The request for registering was sent and executed successfully. The response code SUCCESS is returned.
					--ttsName and VrSynonym params must be added to HMIApplication struct:

				--Begin Test case PositiveRequestCheck.1.1
				--Description: SyncMsgVersion: lower bound (majorVersion = 1, minorVersion = 0)

					-- Precondition: The application should be unregistered before next test.
					function Test:UnregisterAppInterface_Success_SyncMsgVerLowerBound() 

						UnregisterApplicationSessionOne(self) 
					end

					function Test:RegisterAppInterface_SyncMsgVerLowerBound() 

						 --mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 1,
																			minorVersion = 0,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 
					 
						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
							:Timeout(2000)

						EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

					end


				--End Test case PositiveRequestCheck.1.1

				--Begin Test case PositiveRequestCheck.1.2
				--Description: SyncMsgVersion: upper bound (majorVersion = 10, minorVersion = 1000)

					-- Precondition: The application should be unregistered before next test.

					function Test:UnregisterAppInterface_Success_SyncMsgVerUpperBound() 

						UnregisterApplicationSessionOne(self) 
					end

					function Test:RegisterAppInterface_SyncMsgVerUpperBound() 

						 --mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 10,
																			minorVersion = 1000,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 
					 
						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
							:Timeout(2000)

						EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
							
					end


				--End Test case PositiveRequestCheck.1.2

				--Begin Test case PositiveRequestCheck.1.3
				--Description: appName: lower bound = 1

					-- Precondition: The application should be unregistered before next test.

					function Test:UnregisterAppInterface_Success_appNameLowerBound() 

						UnregisterApplicationSessionOne(self) 
					end

					function Test:RegisterAppInterface_appNameLowerBound() 

						 --mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="A",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 
						--hmi side: expected  BasicCommunication.OnAppRegistered
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
					            {
					              	application = 
					              	{
					                	appName = "A",
										policyAppID = "123456",
										hmiDisplayLanguageDesired ="EN-US",
										isMediaApplication = AppMediaType
					              	}
					            })
					 
						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
							:Timeout(2000)

						EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
							
					end


				--End Test case PositiveRequestCheck.1.3


				--Begin Test case PositiveRequestCheck.1.4
				--Description: appName: upper bound = 100

					-- Precondition: The application should be unregistered before next test.

					function Test:UnregisterAppInterface_Success_appNameUpperBound() 

						UnregisterApplicationSessionOne(self) 
					end

					function Test:RegisterAppInterface_appNameUpperBound() 

						 --mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 

						--hmi side: expected  BasicCommunication.OnAppRegistered
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
					            {
					              	application = 
					              	{
					                	appName = "01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg",
										policyAppID = "123456",
										hmiDisplayLanguageDesired ="EN-US",
										isMediaApplication = AppMediaType
					              	}
					            })
					 
						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
							:Timeout(2000)

						EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
							
					end


				--End Test case PositiveRequestCheck.1.4

				--Begin Test case PositiveRequestCheck.1.5
				--Description: appName: spaces before, after and in the middle

					-- Precondition: The application should be unregistered before next test.

					function Test:UnregisterAppInterface_Success_appNameSpaces() 

						UnregisterApplicationSessionOne(self) 
					end

					function Test:RegisterAppInterface_appNameSpaces() 

						 --mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName =" Sync Proxy Tester ",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 

						--hmi side: expected  BasicCommunication.OnAppRegistered
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
					            {
					              	application = 
					              	{
					                	appName = " Sync Proxy Tester ",
										policyAppID = "123456",
										hmiDisplayLanguageDesired ="EN-US",
										isMediaApplication = AppMediaType
					              	}
					            })
					 
						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
							:Timeout(2000)

						EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
							
					end


				--End Test case PositiveRequestCheck.1.5

				--Begin Test case PositiveRequestCheck.1.6
				--Description: ttsName: Array lower bound = 1

					-- Precondition: The application should be unregistered before next test.

					function Test:UnregisterAppInterface_Success_ttsNameArrayLowerBound() 

						UnregisterApplicationSessionOne(self) 
					end

					function Test:RegisterAppInterface_ttsNameArrayLowerBound() 

						 --mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		ttsName = 
																		{ 
																			{ 
																				text ="SyncProxyTester",
																				type ="TEXT"
																			}
																		}, 
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 

						--hmi side: expected  BasicCommunication.OnAppRegistered
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
					            {
					              	application = 
					              	{
					                	appName = "SyncProxyTester",
										policyAppID = "123456",
										hmiDisplayLanguageDesired ="EN-US",
										isMediaApplication = AppMediaType
					              	},
					              	ttsName = 
									{ 
										{ 
											text ="SyncProxyTester",
											type ="TEXT"
										}
									}
					            })
					 
						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
							:Timeout(2000)

						EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
							
					end


				--End Test case PositiveRequestCheck.1.6

				--Begin Test case PositiveRequestCheck.1.7
				--Description: ttsName: Array upper bound = 100

					-- Precondition: The application should be unregistered before next test.

					function Test:UnregisterAppInterface_Success_ttsNameArrayUpperBound() 

						UnregisterApplicationSessionOne(self) 
					end

					function Test:RegisterAppInterface_ttsNameArrayUpperBound() 

						 --mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		ttsName = 
																		{ 
																			 
																			{ 
																				text ="SyncProxyTester1",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester2",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester3",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester4",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester5",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester6",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester7",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester8",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester9",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester10",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester11",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester12",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester13",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester14",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester15",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester16",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester17",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester18",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester19",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester20",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester21",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester22",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester23",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester24",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester25",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester26",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester27",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester28",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester29",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester30",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester31",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester32",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester33",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester34",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester35",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester36",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester37",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester38",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester39",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester40",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester41",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester42",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester43",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester44",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester45",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester46",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester47",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester48",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester49",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester50",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester51",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester52",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester53",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester54",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester55",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester56",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester57",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester58",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester59",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester60",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester61",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester62",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester63",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester64",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester65",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester66",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester67",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester68",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester69",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester70",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester71",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester72",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester73",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester74",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester75",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester76",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester77",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester78",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester79",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester80",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester81",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester82",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester83",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester84",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester85",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester86",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester87",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester88",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester89",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester90",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester91",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester92",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester93",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester94",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester95",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester96",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester97",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester98",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester99",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester100",
																				type ="TEXT",
																			}, 
																		}, 
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 

						--hmi side: expected  BasicCommunication.OnAppRegistered
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
					            {
					              	application = 
					              	{
					                	appName = "SyncProxyTester",
										policyAppID = "123456",
										hmiDisplayLanguageDesired ="EN-US",
										isMediaApplication = AppMediaType
					              	},
									ttsName = 
									{ 
										 
										{ 
											text ="SyncProxyTester1",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester2",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester3",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester4",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester5",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester6",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester7",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester8",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester9",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester10",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester11",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester12",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester13",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester14",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester15",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester16",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester17",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester18",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester19",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester20",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester21",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester22",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester23",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester24",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester25",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester26",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester27",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester28",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester29",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester30",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester31",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester32",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester33",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester34",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester35",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester36",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester37",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester38",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester39",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester40",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester41",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester42",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester43",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester44",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester45",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester46",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester47",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester48",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester49",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester50",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester51",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester52",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester53",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester54",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester55",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester56",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester57",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester58",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester59",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester60",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester61",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester62",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester63",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester64",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester65",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester66",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester67",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester68",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester69",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester70",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester71",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester72",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester73",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester74",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester75",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester76",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester77",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester78",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester79",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester80",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester81",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester82",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester83",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester84",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester85",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester86",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester87",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester88",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester89",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester90",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester91",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester92",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester93",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester94",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester95",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester96",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester97",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester98",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester99",
											type ="TEXT",
										}, 
										 
										{ 
											text ="SyncProxyTester100",
											type ="TEXT",
										}, 
									}
					            })
					 
						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
							:Timeout(2000)

						EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
							
					end


				--End Test case PositiveRequestCheck.1.7

				--Begin Test case PositiveRequestCheck.1.8
				--Description: ttsName.text: lower bound = 1

					-- Precondition: The application should be unregistered before next test.

					function Test:UnregisterAppInterface_Success_ttsNameTextLowerBound() 

						UnregisterApplicationSessionOne(self) 
					end

					function Test:RegisterAppInterface_ttsNameTextLowerBound() 

						 --mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		ttsName = 
																		{ 
																			{ 
																				text ="S",
																				type ="TEXT"
																			}
																		}, 
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 

						--hmi side: expected  BasicCommunication.OnAppRegistered
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
					            {
					              	application = 
					              	{
					                	appName = "SyncProxyTester",
										policyAppID = "123456",
										hmiDisplayLanguageDesired ="EN-US",
										isMediaApplication = AppMediaType
					              	},
					              	ttsName = 
									{ 
										{ 
											text ="S",
											type ="TEXT"
										}
									}
					            })
					 
						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
							:Timeout(2000)

						EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
							
					end


				--End Test case PositiveRequestCheck.1.8

				--Begin Test case PositiveRequestCheck.1.9
				--Description: ttsName.text: upper bound = 500

					-- Precondition: The application should be unregistered before next test.

					function Test:UnregisterAppInterface_Success_ttsNameTextUpperBound() 

						UnregisterApplicationSessionOne(self) 
					end

					function Test:RegisterAppInterface_ttsNameTextUpperBound() 

						 --mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		ttsName = 
																		{ 
																			{ 
																				text ="01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfghijkl",
																				type ="TEXT"
																			}
																		}, 
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 

						--hmi side: expected  BasicCommunication.OnAppRegistered
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
					            {
					              	application = 
					              	{
					                	appName = "SyncProxyTester",
										policyAppID = "123456",
										hmiDisplayLanguageDesired ="EN-US",
										isMediaApplication = AppMediaType
					              	},
					              	ttsName = 
									{ 
										{ 
											text ="01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfghijkl",
											type ="TEXT"
										}
									}
					            })
					 
						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
							:Timeout(2000)

						EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
							
					end


				--End Test case PositiveRequestCheck.1.9

				--Begin Test case PositiveRequestCheck.1.10
				--Description: ttsName.text: lower bound = ""

					--Requirement ID in JAMA: APPLINK-9011, SDLAQ-CRS-2910

					--Verification criteria: In case the mobile application sends any RPC with 'text:""' (empty string) of 'ttsChunk' struct and other valid params (meaning: with all mandatory + conditional-mandatory (if defined) params present and with values valid per mobile_API.xml; non-mandatory params may be omitted), SDL must consider such RPC as valid and transfer it to HMI.

					-- Precondition: The application should be unregistered before next test.

					function Test:UnregisterAppInterface_Success_ttsNameTextOutLowerBound() 

						UnregisterApplicationSessionOne(self) 
					end

					function Test:RegisterAppInterface_ttsNameTextOutLowerBound() 

						 --mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		ttsName = 
																		{ 
																			{ 
																				text ="",
																				type ="TEXT"
																			}
																		}, 
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 

						--hmi side: expected  BasicCommunication.OnAppRegistered
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
					            {
					              	application = 
					              	{
					                	appName = "SyncProxyTester",
										policyAppID = "123456",
										hmiDisplayLanguageDesired ="EN-US",
										isMediaApplication = AppMediaType
					              	},
					              	ttsName = 
									{ 
										{ 
											text ="",
											type ="TEXT"
										}
									}
					            })
					 
						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
							:Timeout(2000)

						EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
							
					end


				--End Test case PositiveRequestCheck.1.10

				--Begin Test case PositiveRequestCheck.1.11
				--Description: ttsName.text: with spaces before, after and in the middle

					-- Precondition: The application should be unregistered before next test.

					function Test:UnregisterAppInterface_Success_ttsNameTextSpaces() 

						UnregisterApplicationSessionOne(self) 
					end

					function Test:RegisterAppInterface_ttsNameTextSpaces() 

						 --mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		ttsName = 
																		{ 
																			{ 
																				text =" Sync Proxy Tester ",
																				type ="TEXT"
																			}
																		}, 
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 

						--hmi side: expected  BasicCommunication.OnAppRegistered
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
					            {
					              	application = 
					              	{
					                	appName = "SyncProxyTester",
										policyAppID = "123456",
										hmiDisplayLanguageDesired ="EN-US",
										isMediaApplication = AppMediaType
					              	},
					              	ttsName = 
									{ 
										{ 
											text =" Sync Proxy Tester ",
											type ="TEXT"
										}
									}
					            })
					 
						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
							:Timeout(2000)

						EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
							
					end


				--End Test case PositiveRequestCheck.1.11

				--Begin Test case PositiveRequestCheck.1.12
				--Description: ngnMediaScreenAppName: lower bound = 1

					-- Precondition: The application should be unregistered before next test.

					function Test:UnregisterAppInterface_Success_ngnNameLowerBound() 

						UnregisterApplicationSessionOne(self) 
					end

					function Test:RegisterAppInterface_ngnNameLowerBound() 

						 --mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		ngnMediaScreenAppName ="S",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 

						--hmi side: expected  BasicCommunication.OnAppRegistered
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
					            {
					              	application = 
					              	{
					                	appName = "SyncProxyTester",
										policyAppID = "123456",
										hmiDisplayLanguageDesired ="EN-US",
										isMediaApplication = AppMediaType,
										ngnMediaScreenAppName ="S"
					              	}
					            })
					 
						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
							:Timeout(2000)

						EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
							
					end


				--End Test case PositiveRequestCheck.1.12

				--Begin Test case PositiveRequestCheck.1.13
				--Description: ngnMediaScreenAppName: lower bound = 100

					-- Precondition: The application should be unregistered before next test.

					function Test:UnregisterAppInterface_Success_ngnNameUpperBound() 

						UnregisterApplicationSessionOne(self) 
					end

					function Test:RegisterAppInterface_ngnNameUpperBound() 

						 --mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		ngnMediaScreenAppName ="01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfgh",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 

						--hmi side: expected  BasicCommunication.OnAppRegistered
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
					            {
					              	application = 
					              	{
					                	appName = "SyncProxyTester",
										policyAppID = "123456",
										hmiDisplayLanguageDesired ="EN-US",
										isMediaApplication = AppMediaType,
										ngnMediaScreenAppName ="01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfgh"
					              	}
					            })
					 
						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
							:Timeout(2000)

						EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

					end


				--End Test case PositiveRequestCheck.1.13

				--Begin Test case PositiveRequestCheck.1.14
				--Description: ngnMediaScreenAppName: with spaces before, after and in the middle

					-- Precondition: The application should be unregistered before next test.

					function Test:UnregisterAppInterface_Success_ngnNameSpaces() 

						UnregisterApplicationSessionOne(self) 
					end

					function Test:RegisterAppInterface_ngnNameSpaces() 

						 --mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		ngnMediaScreenAppName =" S P T ",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 

						--hmi side: expected  BasicCommunication.OnAppRegistered
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
					            {
					              	application = 
					              	{
					                	appName = "SyncProxyTester",
										policyAppID = "123456",
										hmiDisplayLanguageDesired ="EN-US",
										isMediaApplication = AppMediaType,
										ngnMediaScreenAppName =" S P T "
					              	}
					            })
					 
						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
							:Timeout(2000)

						EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
							
					end


				--End Test case PositiveRequestCheck.1.14

				--Begin Test case PositiveRequestCheck.1.15
				--Description: vrSynonyms: Array lower bound = 1

					-- Precondition: The application should be unregistered before next test.

					function Test:UnregisterAppInterface_Success_VRSynArrayLowerBound() 

						UnregisterApplicationSessionOne(self) 
					end

					function Test:RegisterAppInterface_VRSynArrayLowerBound() 

						 --mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		vrSynonyms = 
																		{ 
																			"VRSyncProxyTester1",
																		},
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 

						--hmi side: expected  BasicCommunication.OnAppRegistered
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
					            {
					              	application = 
					              	{
					                	appName = "SyncProxyTester",
										policyAppID = "123456",
										hmiDisplayLanguageDesired ="EN-US",
										isMediaApplication = AppMediaType,
					              	},
					              	vrSynonyms = 
									{ 
										"VRSyncProxyTester1",
									}
					            })
					 
						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
							:Timeout(2000)

						EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
							
					end


				--End Test case PositiveRequestCheck.1.15

				--Begin Test case PositiveRequestCheck.1.16
				--Description: vrSynonyms: Array lower bound = 100

					-- Precondition: The application should be unregistered before next test.

					function Test:UnregisterAppInterface_Success_VRSynArrayUpperBound() 

						UnregisterApplicationSessionOne(self) 
					end

					function Test:RegisterAppInterface_VRSynArrayUpperBound() 

						 --mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		vrSynonyms = 
																		{ 
																			"VRSyncProxyTester1",
																			"VRSyncProxyTester2",
																			"VRSyncProxyTester3",
																			"VRSyncProxyTester4",
																			"VRSyncProxyTester5",
																			"VRSyncProxyTester6",
																			"VRSyncProxyTester7",
																			"VRSyncProxyTester8",
																			"VRSyncProxyTester9",
																			"VRSyncProxyTester10",
																			"VRSyncProxyTester11",
																			"VRSyncProxyTester12",
																			"VRSyncProxyTester13",
																			"VRSyncProxyTester14",
																			"VRSyncProxyTester15",
																			"VRSyncProxyTester16",
																			"VRSyncProxyTester17",
																			"VRSyncProxyTester18",
																			"VRSyncProxyTester19",
																			"VRSyncProxyTester20",
																			"VRSyncProxyTester21",
																			"VRSyncProxyTester22",
																			"VRSyncProxyTester23",
																			"VRSyncProxyTester24",
																			"VRSyncProxyTester25",
																			"VRSyncProxyTester26",
																			"VRSyncProxyTester27",
																			"VRSyncProxyTester28",
																			"VRSyncProxyTester29",
																			"VRSyncProxyTester30",
																			"VRSyncProxyTester31",
																			"VRSyncProxyTester32",
																			"VRSyncProxyTester33",
																			"VRSyncProxyTester34",
																			"VRSyncProxyTester35",
																			"VRSyncProxyTester36",
																			"VRSyncProxyTester37",
																			"VRSyncProxyTester38",
																			"VRSyncProxyTester39",
																			"VRSyncProxyTester40",
																			"VRSyncProxyTester41",
																			"VRSyncProxyTester42",
																			"VRSyncProxyTester43",
																			"VRSyncProxyTester44",
																			"VRSyncProxyTester45",
																			"VRSyncProxyTester46",
																			"VRSyncProxyTester47",
																			"VRSyncProxyTester48",
																			"VRSyncProxyTester49",
																			"VRSyncProxyTester50",
																			"VRSyncProxyTester51",
																			"VRSyncProxyTester52",
																			"VRSyncProxyTester53",
																			"VRSyncProxyTester54",
																			"VRSyncProxyTester55",
																			"VRSyncProxyTester56",
																			"VRSyncProxyTester57",
																			"VRSyncProxyTester58",
																			"VRSyncProxyTester59",
																			"VRSyncProxyTester60",
																			"VRSyncProxyTester61",
																			"VRSyncProxyTester62",
																			"VRSyncProxyTester63",
																			"VRSyncProxyTester64",
																			"VRSyncProxyTester65",
																			"VRSyncProxyTester66",
																			"VRSyncProxyTester67",
																			"VRSyncProxyTester68",
																			"VRSyncProxyTester69",
																			"VRSyncProxyTester70",
																			"VRSyncProxyTester71",
																			"VRSyncProxyTester72",
																			"VRSyncProxyTester73",
																			"VRSyncProxyTester74",
																			"VRSyncProxyTester75",
																			"VRSyncProxyTester76",
																			"VRSyncProxyTester77",
																			"VRSyncProxyTester78",
																			"VRSyncProxyTester79",
																			"VRSyncProxyTester80",
																			"VRSyncProxyTester81",
																			"VRSyncProxyTester82",
																			"VRSyncProxyTester83",
																			"VRSyncProxyTester84",
																			"VRSyncProxyTester85",
																			"VRSyncProxyTester86",
																			"VRSyncProxyTester87",
																			"VRSyncProxyTester88",
																			"VRSyncProxyTester89",
																			"VRSyncProxyTester90",
																			"VRSyncProxyTester91",
																			"VRSyncProxyTester92",
																			"VRSyncProxyTester93",
																			"VRSyncProxyTester94",
																			"VRSyncProxyTester95",
																			"VRSyncProxyTester96",
																			"VRSyncProxyTester97",
																			"VRSyncProxyTester98",
																			"VRSyncProxyTester99",
																			"VRSyncProxyTester100",
																		},
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 

						--hmi side: expected  BasicCommunication.OnAppRegistered
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
					            {
					              	application = 
					              	{
					                	appName = "SyncProxyTester",
										policyAppID = "123456",
										hmiDisplayLanguageDesired ="EN-US",
										isMediaApplication = AppMediaType,
					              	},
					              	vrSynonyms = 
									{ 
										"VRSyncProxyTester1",
										"VRSyncProxyTester2",
										"VRSyncProxyTester3",
										"VRSyncProxyTester4",
										"VRSyncProxyTester5",
										"VRSyncProxyTester6",
										"VRSyncProxyTester7",
										"VRSyncProxyTester8",
										"VRSyncProxyTester9",
										"VRSyncProxyTester10",
										"VRSyncProxyTester11",
										"VRSyncProxyTester12",
										"VRSyncProxyTester13",
										"VRSyncProxyTester14",
										"VRSyncProxyTester15",
										"VRSyncProxyTester16",
										"VRSyncProxyTester17",
										"VRSyncProxyTester18",
										"VRSyncProxyTester19",
										"VRSyncProxyTester20",
										"VRSyncProxyTester21",
										"VRSyncProxyTester22",
										"VRSyncProxyTester23",
										"VRSyncProxyTester24",
										"VRSyncProxyTester25",
										"VRSyncProxyTester26",
										"VRSyncProxyTester27",
										"VRSyncProxyTester28",
										"VRSyncProxyTester29",
										"VRSyncProxyTester30",
										"VRSyncProxyTester31",
										"VRSyncProxyTester32",
										"VRSyncProxyTester33",
										"VRSyncProxyTester34",
										"VRSyncProxyTester35",
										"VRSyncProxyTester36",
										"VRSyncProxyTester37",
										"VRSyncProxyTester38",
										"VRSyncProxyTester39",
										"VRSyncProxyTester40",
										"VRSyncProxyTester41",
										"VRSyncProxyTester42",
										"VRSyncProxyTester43",
										"VRSyncProxyTester44",
										"VRSyncProxyTester45",
										"VRSyncProxyTester46",
										"VRSyncProxyTester47",
										"VRSyncProxyTester48",
										"VRSyncProxyTester49",
										"VRSyncProxyTester50",
										"VRSyncProxyTester51",
										"VRSyncProxyTester52",
										"VRSyncProxyTester53",
										"VRSyncProxyTester54",
										"VRSyncProxyTester55",
										"VRSyncProxyTester56",
										"VRSyncProxyTester57",
										"VRSyncProxyTester58",
										"VRSyncProxyTester59",
										"VRSyncProxyTester60",
										"VRSyncProxyTester61",
										"VRSyncProxyTester62",
										"VRSyncProxyTester63",
										"VRSyncProxyTester64",
										"VRSyncProxyTester65",
										"VRSyncProxyTester66",
										"VRSyncProxyTester67",
										"VRSyncProxyTester68",
										"VRSyncProxyTester69",
										"VRSyncProxyTester70",
										"VRSyncProxyTester71",
										"VRSyncProxyTester72",
										"VRSyncProxyTester73",
										"VRSyncProxyTester74",
										"VRSyncProxyTester75",
										"VRSyncProxyTester76",
										"VRSyncProxyTester77",
										"VRSyncProxyTester78",
										"VRSyncProxyTester79",
										"VRSyncProxyTester80",
										"VRSyncProxyTester81",
										"VRSyncProxyTester82",
										"VRSyncProxyTester83",
										"VRSyncProxyTester84",
										"VRSyncProxyTester85",
										"VRSyncProxyTester86",
										"VRSyncProxyTester87",
										"VRSyncProxyTester88",
										"VRSyncProxyTester89",
										"VRSyncProxyTester90",
										"VRSyncProxyTester91",
										"VRSyncProxyTester92",
										"VRSyncProxyTester93",
										"VRSyncProxyTester94",
										"VRSyncProxyTester95",
										"VRSyncProxyTester96",
										"VRSyncProxyTester97",
										"VRSyncProxyTester98",
										"VRSyncProxyTester99",
										"VRSyncProxyTester100",
									}
					            })
					 
						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
							:Timeout(2000)

						EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
							
					end


				--End Test case PositiveRequestCheck.1.16
				
				--Begin Test case PositiveRequestCheck.1.17
				--Description: vrSynonyms: synonym lower bound = 1
					-- Precondition: The application should be unregistered before next test.

					function Test:UnregisterAppInterface_Success_VRSynLowerBound() 

						UnregisterApplicationSessionOne(self) 
					end

					function Test:RegisterAppInterface_VRSynLowerBound() 

						 --mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		vrSynonyms = 
																		{ 
																			"A",
																		},
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 

						--hmi side: expected  BasicCommunication.OnAppRegistered
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
					            {
					              	application = 
					              	{
					                	appName = "SyncProxyTester",
										policyAppID = "123456",
										hmiDisplayLanguageDesired ="EN-US",
										isMediaApplication = AppMediaType,
					              	},
					              	vrSynonyms = 
									{ 
										"A",
									}
					            })
					 
						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
							:Timeout(2000)

						EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
							
					end


				--End Test case PositiveRequestCheck.1.17

				--Begin Test case PositiveRequestCheck.1.18
				--Description: vrSynonyms: synonym upper bound = 40

					-- Precondition: The application should be unregistered before next test.
					function Test:UnregisterAppInterface_Success_VRSynUpperBound() 
						UnregisterApplicationSessionOne(self) 
					end

					function Test:RegisterAppInterface_VRSynUpperBound() 

						 --mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		vrSynonyms = 
																		{ 
																			"01234567890abcdASDF!@#$%^*()-_+|~{}[]:,|",
																		},
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 

						--hmi side: expected  BasicCommunication.OnAppRegistered
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
					            {
					              	application = 
					              	{
					                	appName = "SyncProxyTester",
										policyAppID = "123456",
										hmiDisplayLanguageDesired ="EN-US",
										isMediaApplication = AppMediaType,
					              	},
					              	vrSynonyms = 
									{ 
										"01234567890abcdASDF!@#$%^*()-_+|~{}[]:,|",
									}
					            })
					 
						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
							:Timeout(2000)

						EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
							
					end


				--End Test case PositiveRequestCheck.1.18

				--Begin Test case PositiveRequestCheck.1.19
				--Description: vrSynonyms: synonym with spaces before, after, in the middle
					-- Precondition: The application should be unregistered before next test.

					function Test:UnregisterAppInterface_Success_VRSynSpaces() 

						UnregisterApplicationSessionOne(self) 
					end

					function Test:RegisterAppInterface_VRSynSpaces() 

						 --mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		vrSynonyms = 
																		{ 
																			" SpaceBefore",
																			"SpaceAfter ",
																			"Space in the middle"
																		},
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 

						--hmi side: expected  BasicCommunication.OnAppRegistered
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
					            {
					              	application = 
					              	{
					                	appName = "SyncProxyTester",
										policyAppID = "123456",
										hmiDisplayLanguageDesired ="EN-US",
										isMediaApplication = AppMediaType,
					              	},
					              	vrSynonyms = 
									{ 
										" SpaceBefore",
										"SpaceAfter ",
										"Space in the middle"
									}
					            })
					 
						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
							:Timeout(2000)

						EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
							
					end


				--End Test case PositiveRequestCheck.1.19

				--Begin Test case PositiveRequestCheck.1.20
				--Description: isMediaApplication: parameter = True
					-- Precondition: The application should be unregistered before next test.

					function Test:UnregisterAppInterface_Success_isMediaTrue() 

						UnregisterApplicationSessionOne(self) 
					end

					function Test:RegisterAppInterface_isMediaTrue() 

						--mobile side: RegisterAppInterface request 
						self.mobileSession.correlationId = self.mobileSession.correlationId + 1

						  local msg = 
						  {
						    serviceType      = 7,
						    frameInfo        = 0,
						    rpcType          = 0,
						    rpcFunctionId    = 1,
						    rpcCorrelationId = self.mobileSession.correlationId,
						    payload          = '{"languageDesired":"EN-US","appID":"123456","appName":"SyncProxyTester","syncMsgVersion":{"minorVersion":2,"majorVersion":2},"isMediaApplication":True,"hmiDisplayLanguageDesired":"EN-US"}'
						  }
						  self.mobileSession:Send(msg)
						 

						--hmi side: expected  BasicCommunication.OnAppRegistered
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
					            {
					              	application = 
					              	{
					                	appName = "SyncProxyTester",
										policyAppID = "123456",
										hmiDisplayLanguageDesired ="EN-US",
										isMediaApplication = true,
					              	}
					            })
					 
						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE("RegisterAppInterface", { success = true, resultCode = "SUCCESS"})
							:Timeout(2000)

						EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
							
					end


				--End Test case PositiveRequestCheck.1.20

				--Begin Test case PositiveRequestCheck.1.21
				--Description: isMediaApplication: parameter = false
					-- Precondition: The application should be unregistered before next test.

					function Test:UnregisterAppInterface_Success_isMediafalse() 

						UnregisterApplicationSessionOne(self) 
					end

					function Test:RegisterAppInterface_isMediafalse() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = false,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 
						 
						--hmi side: expected  BasicCommunication.OnAppRegistered
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
					            {
					              	application = 
					              	{
					                	appName = "SyncProxyTester",
										policyAppID = "123456",
										hmiDisplayLanguageDesired ="EN-US",
										isMediaApplication = false,
					              	}
					            })
					 
						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
							:Timeout(2000)

						EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
							
					end


				--End Test case PositiveRequestCheck.1.21

				--Begin Test case PositiveRequestCheck.1.22
				--Description: appHMIType: Array lower bound = 1

					-- Precondition: The application should be unregistered before next test.

					function Test:UnregisterAppInterface_Success_appHMITypeArrayLowerBound() 

						UnregisterApplicationSessionOne(self) 
					end

					function Test:RegisterAppInterface_appHMITypeArrayLowerBound() 

						 --mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appHMIType = 
																		{ 
																			"DEFAULT",
																		}, 
																		appID ="123456",
																	
																	})

						--hmi side: expected  BasicCommunication.OnAppRegistered
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
					            {
					              	application = 
					              	{
					                	appName = "SyncProxyTester",
										policyAppID = "123456",
										hmiDisplayLanguageDesired ="EN-US",
										isMediaApplication = AppMediaType,
										appType = 
										{ 
											"DEFAULT",
										}
					              	}
					            })
					 
						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
							:Timeout(2000) 

						EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

					end

				--End Test case PositiveRequestCheck.1.22

				--Begin Test case PositiveRequestCheck.1.23
				--Description: appHMIType: Array upper bound = 100

					-- Precondition: The application should be unregistered before next test.

					function Test:UnregisterAppInterface_Success_appHMITypeArrayUpperBound() 

						UnregisterApplicationSessionOne(self) 
					end

					function Test:RegisterAppInterface_appHMITypeArrayUpperBound() 

						 --mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appHMIType = 
																		{ 
																			"DEFAULT",
																			"COMMUNICATION",
																			"MEDIA",
																			"MESSAGING",
																			"NAVIGATION",
																			"INFORMATION",
																			"SOCIAL",
																			"BACKGROUND_PROCESS",
																			"TESTING",
																			"SYSTEM",
																			"DEFAULT",
																			"COMMUNICATION",
																			"MEDIA",
																			"MESSAGING",
																			"NAVIGATION",
																			"INFORMATION",
																			"SOCIAL",
																			"BACKGROUND_PROCESS",
																			"TESTING",
																			"SYSTEM",
																			"DEFAULT",
																			"COMMUNICATION",
																			"MEDIA",
																			"MESSAGING",
																			"NAVIGATION",
																			"INFORMATION",
																			"SOCIAL",
																			"BACKGROUND_PROCESS",
																			"TESTING",
																			"SYSTEM",
																			"DEFAULT",
																			"COMMUNICATION",
																			"MEDIA",
																			"MESSAGING",
																			"NAVIGATION",
																			"INFORMATION",
																			"SOCIAL",
																			"BACKGROUND_PROCESS",
																			"TESTING",
																			"SYSTEM",
																			"DEFAULT",
																			"COMMUNICATION",
																			"MEDIA",
																			"MESSAGING",
																			"NAVIGATION",
																			"INFORMATION",
																			"SOCIAL",
																			"BACKGROUND_PROCESS",
																			"TESTING",
																			"SYSTEM",
																			"DEFAULT",
																			"COMMUNICATION",
																			"MEDIA",
																			"MESSAGING",
																			"NAVIGATION",
																			"INFORMATION",
																			"SOCIAL",
																			"BACKGROUND_PROCESS",
																			"TESTING",
																			"SYSTEM",
																			"DEFAULT",
																			"COMMUNICATION",
																			"MEDIA",
																			"MESSAGING",
																			"NAVIGATION",
																			"INFORMATION",
																			"SOCIAL",
																			"BACKGROUND_PROCESS",
																			"TESTING",
																			"SYSTEM",
																			"DEFAULT",
																			"COMMUNICATION",
																			"MEDIA",
																			"MESSAGING",
																			"NAVIGATION",
																			"INFORMATION",
																			"SOCIAL",
																			"BACKGROUND_PROCESS",
																			"TESTING",
																			"SYSTEM",
																			"DEFAULT",
																			"COMMUNICATION",
																			"MEDIA",
																			"MESSAGING",
																			"NAVIGATION",
																			"INFORMATION",
																			"SOCIAL",
																			"BACKGROUND_PROCESS",
																			"TESTING",
																			"SYSTEM",
																			"DEFAULT",
																			"COMMUNICATION",
																			"MEDIA",
																			"MESSAGING",
																			"NAVIGATION",
																			"INFORMATION",
																			"SOCIAL",
																			"BACKGROUND_PROCESS",
																			"TESTING",
																			"SYSTEM"
																		}, 
																		appID ="123456",
																	
																	})

						--hmi side: expected  BasicCommunication.OnAppRegistered
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
					            {
					              	application = 
					              	{
					                	appName = "SyncProxyTester",
										policyAppID = "123456",
										hmiDisplayLanguageDesired ="EN-US",
										isMediaApplication = AppMediaType,
										appType = 
										{ 
											"DEFAULT",
											"COMMUNICATION",
											"MEDIA",
											"MESSAGING",
											"NAVIGATION",
											"INFORMATION",
											"SOCIAL",
											"BACKGROUND_PROCESS",
											"TESTING",
											"SYSTEM",
											"DEFAULT",
											"COMMUNICATION",
											"MEDIA",
											"MESSAGING",
											"NAVIGATION",
											"INFORMATION",
											"SOCIAL",
											"BACKGROUND_PROCESS",
											"TESTING",
											"SYSTEM",
											"DEFAULT",
											"COMMUNICATION",
											"MEDIA",
											"MESSAGING",
											"NAVIGATION",
											"INFORMATION",
											"SOCIAL",
											"BACKGROUND_PROCESS",
											"TESTING",
											"SYSTEM",
											"DEFAULT",
											"COMMUNICATION",
											"MEDIA",
											"MESSAGING",
											"NAVIGATION",
											"INFORMATION",
											"SOCIAL",
											"BACKGROUND_PROCESS",
											"TESTING",
											"SYSTEM",
											"DEFAULT",
											"COMMUNICATION",
											"MEDIA",
											"MESSAGING",
											"NAVIGATION",
											"INFORMATION",
											"SOCIAL",
											"BACKGROUND_PROCESS",
											"TESTING",
											"SYSTEM",
											"DEFAULT",
											"COMMUNICATION",
											"MEDIA",
											"MESSAGING",
											"NAVIGATION",
											"INFORMATION",
											"SOCIAL",
											"BACKGROUND_PROCESS",
											"TESTING",
											"SYSTEM",
											"DEFAULT",
											"COMMUNICATION",
											"MEDIA",
											"MESSAGING",
											"NAVIGATION",
											"INFORMATION",
											"SOCIAL",
											"BACKGROUND_PROCESS",
											"TESTING",
											"SYSTEM",
											"DEFAULT",
											"COMMUNICATION",
											"MEDIA",
											"MESSAGING",
											"NAVIGATION",
											"INFORMATION",
											"SOCIAL",
											"BACKGROUND_PROCESS",
											"TESTING",
											"SYSTEM",
											"DEFAULT",
											"COMMUNICATION",
											"MEDIA",
											"MESSAGING",
											"NAVIGATION",
											"INFORMATION",
											"SOCIAL",
											"BACKGROUND_PROCESS",
											"TESTING",
											"SYSTEM",
											"DEFAULT",
											"COMMUNICATION",
											"MEDIA",
											"MESSAGING",
											"NAVIGATION",
											"INFORMATION",
											"SOCIAL",
											"BACKGROUND_PROCESS",
											"TESTING",
											"SYSTEM"
										}
					              	}
					            })
					 
						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
							:Timeout(2000) 

						EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

					end

				--End Test case PositiveRequestCheck.1.23

				--Begin Test case PositiveRequestCheck.1.24
				--Description: appID: lower bound = 1

					-- Precondition: The application should be unregistered before next test.

					function Test:UnregisterAppInterface_Success_appIDLowerBound() 

						UnregisterApplicationSessionOne(self) 
					end

					function Test:RegisterAppInterface_appIDLowerBound() 

						 --mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="A",
																	
																	}) 
 

						--hmi side: expected  BasicCommunication.OnAppRegistered
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
					            {
					              	application = 
					              	{
					                	appName = "SyncProxyTester",
										policyAppID = "A",
										hmiDisplayLanguageDesired ="EN-US",
										isMediaApplication = AppMediaType
					              	}
					            })
					 
						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
							:Timeout(2000) 

						EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

					end

				--End Test case PositiveRequestCheck.1.24

				--Begin Test case PositiveRequestCheck.1.25
				--Description: appID: upper bound = 100

					-- Precondition: The application should be unregistered before next test.

					function Test:UnregisterAppInterface_Success_appIDUpperBound() 

						UnregisterApplicationSessionOne(self) 
					end

					function Test:RegisterAppInterface_appIDUpperBound() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfgh",
																	
																	}) 

						--hmi side: expected  BasicCommunication.OnAppRegistered
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
					            {
					              	application = 
					              	{
					                	appName = "SyncProxyTester",
										policyAppID = "01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfgh",
										hmiDisplayLanguageDesired ="EN-US",
										isMediaApplication = AppMediaType
					              	}
					            })
					 
						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
							:Timeout(2000) 

						EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

					end

				--End Test case PositiveRequestCheck.1.25

				--Begin Test case PositiveRequestCheck.1.26
				--Description: appID: with spaces before, after and in the middle

					-- Precondition: The application should be unregistered before next test.

					function Test:UnregisterAppInterface_Success_appIDSpaces() 

						UnregisterApplicationSessionOne(self) 
					end

					function Test:RegisterAppInterface_appIDSpaces() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID =" A1 B1 ",
																	
																	}) 

						--hmi side: expected  BasicCommunication.OnAppRegistered
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
					            {
					              	application = 
					              	{
					                	appName = "SyncProxyTester",
										policyAppID = " A1 B1 ",
										hmiDisplayLanguageDesired ="EN-US",
										isMediaApplication = AppMediaType
					              	}
					            })
					 
						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
							:Timeout(2000) 

						EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

					end

				--End Test case PositiveRequestCheck.1.26


				--Begin Test case PositiveRequestCheck.1.27
				--Description: DeviceInfo.hardware: lower bound = 1

					-- Precondition: The application should be unregistered before next test.

					function Test:UnregisterAppInterface_Success_hardwareLowerBound() 

						UnregisterApplicationSessionOne(self) 
					end

					function Test:RegisterAppInterface_hardwareLowerBound() 

						 --mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																		deviceInfo = {hardware = "a"}
																	
																	}) 
 

						--hmi side: expected  BasicCommunication.OnAppRegistered
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
					            {
					              	application = 
					              	{
					                	appName = "SyncProxyTester",
										policyAppID = "123456",
										hmiDisplayLanguageDesired ="EN-US",
										isMediaApplication = AppMediaType,
										--[=[TODO: update after resolving APPLINK-16052

										deviceInfo = 
										{
											name = "127.0.0.1",
											id = config.deviceMAC,
											transportType = "WIFI",
											isSDLAllowed = true
										}]=]
					              	}
					            })
					 
						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
							:Timeout(2000) 

						EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

					end

				--End Test case PositiveRequestCheck.1.27

				--Begin Test case PositiveRequestCheck.1.28
				--Description: DeviceInfo.hardware: upper bound = 500

					-- Precondition: The application should be unregistered before next test.

					function Test:UnregisterAppInterface_Success_hardwareUpperBound() 

						UnregisterApplicationSessionOne(self) 
					end

					function Test:RegisterAppInterface_hardwareUpperBound() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																		deviceInfo = {hardware = "01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01"}
																	
																	}) 

						--hmi side: expected  BasicCommunication.OnAppRegistered
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
					            {
					              	application = 
					              	{
					                	appName = "SyncProxyTester",
										policyAppID = "123456",
										hmiDisplayLanguageDesired ="EN-US",
										isMediaApplication = AppMediaType,
										--[=[TODO: update after resolving APPLINK-16052

										deviceInfo = 
										{
											name = "127.0.0.1",
											id = config.deviceMAC,
											transportType = "WIFI",
											isSDLAllowed = true
										}]=]
					              	}
					            })
					 
						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
							:Timeout(2000) 

						EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

					end

				--End Test case PositiveRequestCheck.1.28

				--Begin Test case PositiveRequestCheck.1.29
				--Description: DeviceInfo.hardware: with spaces before, after and in the middle

					-- Precondition: The application should be unregistered before next test.

					function Test:UnregisterAppInterface_Success_hardwareSpaces() 

						UnregisterApplicationSessionOne(self) 
					end

					function Test:RegisterAppInterface_hardwareSpaces() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																		deviceInfo = {hardware = " hard ware " }
																	
																	}) 

						--hmi side: expected  BasicCommunication.OnAppRegistered
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
					            {
					              	application = 
					              	{
					                	appName = "SyncProxyTester",
										policyAppID = "123456",
										hmiDisplayLanguageDesired ="EN-US",
										isMediaApplication = AppMediaType,
										--[=[TODO: update after resolving APPLINK-16052

										deviceInfo = {
											name = "127.0.0.1",
											id = config.deviceMAC,
											transportType = "WIFI",
											isSDLAllowed = true
										}]=]
					              	}
					            })
					 
						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
							:Timeout(2000) 

						EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

					end

				--End Test case PositiveRequestCheck.1.29

				--Begin Test case PositiveRequestCheck.1.30
				--Description: DeviceInfo.firmwareRev: lower bound = 1

					-- Precondition: The application should be unregistered before next test.

					function Test:UnregisterAppInterface_Success_firmwareRevLowerBound() 

						UnregisterApplicationSessionOne(self) 
					end

					function Test:RegisterAppInterface_firmwareRevLowerBound() 

						 --mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																		deviceInfo = {firmwareRev = "a"}
																	
																	}) 
 

						--hmi side: expected  BasicCommunication.OnAppRegistered
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
					            {
					              	application = 
					              	{
					                	appName = "SyncProxyTester",
										policyAppID = "123456",
										hmiDisplayLanguageDesired ="EN-US",
										isMediaApplication = AppMediaType,
										--[=[TODO: update after resolving APPLINK-16052

										deviceInfo = {firmwareRev = "a"}]=]
					              	}
					            })
					 
						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
							:Timeout(2000) 

						EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

					end

				--End Test case PositiveRequestCheck.1.30

				--Begin Test case PositiveRequestCheck.1.31
				--Description: DeviceInfo.firmwareRev: upper bound = 500

					-- Precondition: The application should be unregistered before next test.

					function Test:UnregisterAppInterface_Success_firmwareRevUpperBound() 

						UnregisterApplicationSessionOne(self) 
					end

					function Test:RegisterAppInterface_firmwareRevUpperBound() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																		deviceInfo = {firmwareRev = "01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01"}
																	
																	}) 

						--hmi side: expected  BasicCommunication.OnAppRegistered
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
					            {
					              	application = 
					              	{
					                	appName = "SyncProxyTester",
										policyAppID = "123456",
										hmiDisplayLanguageDesired ="EN-US",
										isMediaApplication = AppMediaType,
										--[=[TODO: update after resolving APPLINK-16052

										deviceInfo = {firmwareRev = "01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01"}]=]
					              	}
					            })
					 
						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
							:Timeout(2000) 

						EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

					end

				--End Test case PositiveRequestCheck.1.31

				--Begin Test case PositiveRequestCheck.1.32
				--Description: DeviceInfo.firmwareRev: with spaces before, after and in the middle

					-- Precondition: The application should be unregistered before next test.

					function Test:UnregisterAppInterface_Success_firmwareRevSpaces() 

						UnregisterApplicationSessionOne(self) 
					end

					function Test:RegisterAppInterface_firmwareRevSpaces() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																		deviceInfo = {firmwareRev = " hard ware Rev " }
																	
																	}) 

						--hmi side: expected  BasicCommunication.OnAppRegistered
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
					            {
					              	application = 
					              	{
					                	appName = "SyncProxyTester",
										policyAppID = "123456",
										hmiDisplayLanguageDesired ="EN-US",
										isMediaApplication = AppMediaType,
										--[=[TODO: update after resolving APPLINK-16052

										deviceInfo = {firmwareRev = " hard ware Rev " }]=]
					              	}
					            })
					 
						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
							:Timeout(2000) 

						EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

					end

				--End Test case PositiveRequestCheck.1.32

				--Begin Test case PositiveRequestCheck.1.33
				--Description: DeviceInfo.os: lower bound = 1

					-- Precondition: The application should be unregistered before next test.

					function Test:UnregisterAppInterface_Success_osLowerBound() 

						UnregisterApplicationSessionOne(self) 
					end

					function Test:RegisterAppInterface_osLowerBound() 

						 --mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																		deviceInfo = {os = "a"}
																	
																	}) 
 

						--hmi side: expected  BasicCommunication.OnAppRegistered
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
					            {
					              	application = 
					              	{
					                	appName = "SyncProxyTester",
										policyAppID = "123456",
										hmiDisplayLanguageDesired ="EN-US",
										isMediaApplication = AppMediaType,
										--[=[TODO: update after resolving APPLINK-16052

										deviceInfo = {os = "a"}]=]
					              	}
					            })
					 
						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
							:Timeout(2000) 

						EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

					end

				--End Test case PositiveRequestCheck.1.33

				--Begin Test case PositiveRequestCheck.1.34
				--Description: DeviceInfo.os: upper bound = 500

					-- Precondition: The application should be unregistered before next test.

					function Test:UnregisterAppInterface_Success_osUpperBound() 

						UnregisterApplicationSessionOne(self) 
					end

					function Test:RegisterAppInterface_osUpperBound() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																		deviceInfo = {os = "01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01"}
																	
																	}) 

						--hmi side: expected  BasicCommunication.OnAppRegistered
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
					            {
					              	application = 
					              	{
					                	appName = "SyncProxyTester",
										policyAppID = "123456",
										hmiDisplayLanguageDesired ="EN-US",
										isMediaApplication = AppMediaType,
										--[=[TODO: update after resolving APPLINK-16052

										deviceInfo = {os = "01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01"}]=]
					              	}
					            })
					 
						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
							:Timeout(2000) 

						EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

					end

				--End Test case PositiveRequestCheck.1.34

				--Begin Test case PositiveRequestCheck.1.35
				--Description: DeviceInfo.os: with spaces before, after and in the middle

					-- Precondition: The application should be unregistered before next test.

					function Test:UnregisterAppInterface_Success_osSpaces() 

						UnregisterApplicationSessionOne(self) 
					end

					function Test:RegisterAppInterface_osSpaces() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																		deviceInfo = {os = " os QNX 4.2 " }
																	
																	}) 

						--hmi side: expected  BasicCommunication.OnAppRegistered
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
					            {
					              	application = 
					              	{
					                	appName = "SyncProxyTester",
										policyAppID = "123456",
										hmiDisplayLanguageDesired ="EN-US",
										isMediaApplication = AppMediaType,
										--[=[TODO: update after resolving APPLINK-16052

										deviceInfo = {os = " os QNX 4.2 " }]=]
					              	}
					            })
					 
						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
							:Timeout(2000) 

						EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

					end

				--End Test case PositiveRequestCheck.1.35

				--Begin Test case PositiveRequestCheck.1.36
				--Description: DeviceInfo.osVersion: lower bound = 1

					-- Precondition: The application should be unregistered before next test.

					function Test:UnregisterAppInterface_Success_osVersionLowerBound() 

						UnregisterApplicationSessionOne(self) 
					end

					function Test:RegisterAppInterface_osVersionLowerBound() 

						 --mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																		deviceInfo = {osVersion = "a"}
																	
																	}) 
 

						--hmi side: expected  BasicCommunication.OnAppRegistered
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
					            {
					              	application = 
					              	{
					                	appName = "SyncProxyTester",
										policyAppID = "123456",
										hmiDisplayLanguageDesired ="EN-US",
										isMediaApplication = AppMediaType,
										--[=[TODO: update after resolving APPLINK-16052

										deviceInfo = {osVersion = "a"}]=]
					              	}
					            })
					 
						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
							:Timeout(2000) 

						EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

					end

				--End Test case PositiveRequestCheck.1.36

				--Begin Test case PositiveRequestCheck.1.37
				--Description: DeviceInfo.osVersion: upper bound = 500

					-- Precondition: The application should be unregistered before next test.

					function Test:UnregisterAppInterface_Success_osVersionUpperBound() 

						UnregisterApplicationSessionOne(self) 
					end

					function Test:RegisterAppInterface_osVersionUpperBound() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																		deviceInfo = {osVersion = "01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01"}
																	
																	}) 

						--hmi side: expected  BasicCommunication.OnAppRegistered
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
					            {
					              	application = 
					              	{
					                	appName = "SyncProxyTester",
										policyAppID = "123456",
										hmiDisplayLanguageDesired ="EN-US",
										isMediaApplication = AppMediaType,
										--[=[TODO: update after resolving APPLINK-16052

										deviceInfo = {osVersion = "01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01"}]=]
					              	}
					            })
					 
						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
							:Timeout(2000) 

						EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

					end

				--End Test case PositiveRequestCheck.1.37

				--Begin Test case PositiveRequestCheck.1.38
				--Description: DeviceInfo.osVersion: with spaces before, after and in the middle

					-- Precondition: The application should be unregistered before next test.

					function Test:UnregisterAppInterface_Success_osVersionSpaces() 

						UnregisterApplicationSessionOne(self) 
					end

					function Test:RegisterAppInterface_osVersionSpaces() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																		deviceInfo = {osVersion = " os Version " }
																	
																	}) 

						--hmi side: expected  BasicCommunication.OnAppRegistered
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
					            {
					              	application = 
					              	{
					                	appName = "SyncProxyTester",
										policyAppID = "123456",
										hmiDisplayLanguageDesired ="EN-US",
										isMediaApplication = AppMediaType,
										--[=[TODO: update after resolving APPLINK-16052

										deviceInfo = {osVersion = " os Version " }]=]
					              	}
					            })
					 
						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
							:Timeout(2000) 

						EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

					end

				--End Test case PositiveRequestCheck.1.38

				--Begin Test case PositiveRequestCheck.1.39
				--Description: DeviceInfo.carrier: lower bound = 1

					-- Precondition: The application should be unregistered before next test.

					function Test:UnregisterAppInterface_Success_carrierLowerBound() 

						UnregisterApplicationSessionOne(self) 
					end

					function Test:RegisterAppInterface_carrierLowerBound() 

						 --mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																		deviceInfo = {carrier = "a"}
																	
																	}) 
 

						--hmi side: expected  BasicCommunication.OnAppRegistered
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
					            {
					              	application = 
					              	{
					                	appName = "SyncProxyTester",
										policyAppID = "123456",
										hmiDisplayLanguageDesired ="EN-US",
										isMediaApplication = AppMediaType,
										--[=[TODO: update after resolving APPLINK-16052

										deviceInfo = {carrier = "a"}]=]
					              	}
					            })
					 
						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
							:Timeout(2000) 

						EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

					end

				--End Test case PositiveRequestCheck.1.39

				--Begin Test case PositiveRequestCheck.1.40
				--Description: DeviceInfo.carrier: upper bound = 500

					-- Precondition: The application should be unregistered before next test.

					function Test:UnregisterAppInterface_Success_carrierUpperBound() 

						UnregisterApplicationSessionOne(self) 
					end

					function Test:RegisterAppInterface_carrierUpperBound() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																		deviceInfo = {carrier = "01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01"}
																	
																	}) 

						--hmi side: expected  BasicCommunication.OnAppRegistered
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
					            {
					              	application = 
					              	{
					                	appName = "SyncProxyTester",
										policyAppID = "123456",
										hmiDisplayLanguageDesired ="EN-US",
										isMediaApplication = AppMediaType,
										--[=[TODO: update after resolving APPLINK-16052

										deviceInfo = {carrier = "01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01"}]=]
					              	}
					            })
					 
						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
							:Timeout(2000) 

						EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

					end

				--End Test case PositiveRequestCheck.1.40

				--Begin Test case PositiveRequestCheck.1.41
				--Description: DeviceInfo.carrier: with spaces before, after and in the middle

					-- Precondition: The application should be unregistered before next test.

					function Test:UnregisterAppInterface_Success_carrierSpaces() 

						UnregisterApplicationSessionOne(self) 
					end

					function Test:RegisterAppInterface_carrierSpaces() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																		deviceInfo = {carrier = " os Version " }
																	
																	}) 

						--hmi side: expected  BasicCommunication.OnAppRegistered
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
					            {
					              	application = 
					              	{
					                	appName = "SyncProxyTester",
										policyAppID = "123456",
										hmiDisplayLanguageDesired ="EN-US",
										isMediaApplication = AppMediaType,
										--[=[TODO: update after resolving APPLINK-16052

										deviceInfo = {carrier = " os Version " }]=]
					              	}
					            })
					 
						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
							:Timeout(2000) 

						EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

					end

				--End Test case PositiveRequestCheck.1.41

				--Begin Test case PositiveRequestCheck.1.42
				--Description: DeviceInfo.maxNumberRFCOMMPorts: lower bound = 1

					-- Precondition: The application should be unregistered before next test.

					function Test:UnregisterAppInterface_maxNumberRFCOMMPortsLowerBound() 

						UnregisterApplicationSessionOne(self) 
					end

					function Test:RegisterAppInterface_maxNumberRFCOMMPortsLowerBound() 

						 --mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																		deviceInfo = {maxNumberRFCOMMPorts = 0}
																	
																	}) 
 

						--hmi side: expected  BasicCommunication.OnAppRegistered
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
					            {
					              	application = 
					              	{
					                	appName = "SyncProxyTester",
										policyAppID = "123456",
										hmiDisplayLanguageDesired ="EN-US",
										isMediaApplication = AppMediaType,
										--[=[TODO: update after resolving APPLINK-16052

										deviceInfo = {maxNumberRFCOMMPorts = 0}]=]
					              	}
					            })
					 
						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
							:Timeout(2000) 

						EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

					end

				--End Test case PositiveRequestCheck.1.42

				--Begin Test case PositiveRequestCheck.1.43
				--Description: DeviceInfo.maxNumberRFCOMMPorts: upper bound = 500

					-- Precondition: The application should be unregistered before next test.

					function Test:UnregisterAppInterface_Success_maxNumberRFCOMMPortsUpperBound() 

						UnregisterApplicationSessionOne(self) 
					end

					function Test:RegisterAppInterface_maxNumberRFCOMMPortsUpperBound() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																		deviceInfo = {maxNumberRFCOMMPorts = 100 }
																	
																	}) 

						--hmi side: expected  BasicCommunication.OnAppRegistered
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
					            {
					              	application = 
					              	{
					                	appName = "SyncProxyTester",
										policyAppID = "123456",
										hmiDisplayLanguageDesired ="EN-US",
										isMediaApplication = AppMediaType,
										--[=[TODO: update after resolving APPLINK-16052

										deviceInfo = {maxNumberRFCOMMPorts = 100 }]=]
					              	}
					            })
					 
						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
							:Timeout(2000) 

						EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

					end

				--End Test case PositiveRequestCheck.1.43


				--Begin Test case PositiveRequestCheck.1.44
				--Description: RegisterAppInterface lower bound

					-- Precondition: The application should be unregistered before next test.

					function Test:UnregisterAppInterface_Success_LowerBound() 

						UnregisterApplicationSessionOne(self) 
					end


					function Test:RegisterAppInterface_LowerBound() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 1,
																			minorVersion = 2,
																		}, 
																		appName ="S",
																		ttsName = 
																		{ 
																			 
																			{ 
																				text ="S",
																				type ="TEXT",
																			}, 
																		}, 
																		ngnMediaScreenAppName ="S",
																		vrSynonyms = 
																		{ 
																			"V",
																		}, 
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appHMIType = 
																		{ 
																			"DEFAULT",
																		}, 
																		appID ="1",
																		deviceInfo = 
																		{
																			hardware = "a",
																			firmwareRev = "a",
																			os = "a",
																			osVersion = "a",
																			carrier = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																			maxNumberRFCOMMPorts = 0
																		}
																	
																	}) 

						--hmi side: expected  BasicCommunication.OnAppRegistered
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
					            {
					              	application = 
					              	{
					                	appName = "S",
										policyAppID = "1",
										hmiDisplayLanguageDesired ="EN-US",
										isMediaApplication = AppMediaType
					              	}
					            })
					 
						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
							:Timeout(2000) 

						EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

					end

				--End Test case PositiveRequestCheck.1.44

				--Begin Test case PositiveRequestCheck.1.45
				--Description: RegisterAppInterface upper bound

					-- Precondition: The application should be unregistered before next test.

					function Test:UnregisterAppInterface_Success_UpperBound() 

						UnregisterApplicationSessionOne(self) 
					end

					function Test:RegisterAppInterface_UpperBound() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 10,
																			minorVersion = 1000,
																		}, 
																		appName ="nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn",
																		ttsName = 
																		{ 
																			 
																			{ 
																				text ="1aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="2aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="3aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="4aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="5aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="6aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="7aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="8aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="9aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="10aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																--<!--1
																			 
																			{ 
																				text ="11aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="12aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="13aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="14aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="15aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="16aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="17aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="18aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="19aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="20aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																--<!--2
																			 
																			{ 
																				text ="21aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="22aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="23aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="24aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="25aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="26aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="27aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="28aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="29aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="30aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																--<!--3
																			 
																			{ 
																				text ="31aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="32aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="33aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="34aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="35aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="36aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="37aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="38aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="39aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="40aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																--<!--4
																			 
																			{ 
																				text ="41aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="42aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="43aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="44aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="45aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="46aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="47aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="48aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="49aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="50aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																--<!--5
																			 
																			{ 
																				text ="51aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="52aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="53aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="54aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="55aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="56aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="57aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="58aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="59aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="60aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																--<!--6
																			 
																			{ 
																				text ="61aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="62aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="63aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="64aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="65aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="66aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="67aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="68aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="69aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="70aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																--<!--7
																			 
																			{ 
																				text ="71aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="72aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="73aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="74aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="75aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="76aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="77aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="78aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="79aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="80aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																--<!--8
																			 
																			{ 
																				text ="81aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="82aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="83aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="84aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="85aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="86aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="87aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="88aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="89aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="90aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																--<!--9
																			 
																			{ 
																				text ="91aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="92aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="93aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="94aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="95aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="96aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="97aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="98aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="99aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="100aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																				type ="TEXT",
																			}, 
																		}, 
																		ngnMediaScreenAppName ="ssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss",
																		vrSynonyms = 
																		{ 
																			"1vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"2vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"3vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"4vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"5vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"6vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"7vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"8vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"9vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"10vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"11vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"12vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"13vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"14vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"15vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"16vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"17vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"18vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"19vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"20vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"21vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"22vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"23vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"24vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"25vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"26vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"27vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"28vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"29vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"30vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"31vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"32vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"33vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"34vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"35vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"36vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"37vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"38vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"39vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"40vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"41vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"42vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"43vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"44vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"45vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"46vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"47vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"48vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"49vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"50vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"51vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"52vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"53vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"54vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"55vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"56vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"57vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"58vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"59vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"60vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"61vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"62vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"63vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"64vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"65vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"66vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"67vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"68vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"69vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"70vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"71vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"72vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"73vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"74vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"75vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"76vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"77vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"78vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"79vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"80vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"81vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"82vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"83vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"84vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"85vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"86vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"87vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"88vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"89vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"90vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"91vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"92vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"93vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"94vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"95vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"96vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"97vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"98vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"99vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																			"100vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv",
																		}, 
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appHMIType = 
																		{ 
																			"DEFAULT",
																			"COMMUNICATION",
																			"MEDIA",
																			"MESSAGING",
																			"NAVIGATION",
																			"INFORMATION",
																			"SOCIAL",
																			"BACKGROUND_PROCESS",
																			"TESTING",
																			"SYSTEM",
																			"DEFAULT",
																			"COMMUNICATION",
																			"MEDIA",
																			"MESSAGING",
																			"NAVIGATION",
																			"INFORMATION",
																			"SOCIAL",
																			"BACKGROUND_PROCESS",
																			"TESTING",
																			"SYSTEM",
																			"DEFAULT",
																			"COMMUNICATION",
																			"MEDIA",
																			"MESSAGING",
																			"NAVIGATION",
																			"INFORMATION",
																			"SOCIAL",
																			"BACKGROUND_PROCESS",
																			"TESTING",
																			"SYSTEM",
																			"DEFAULT",
																			"COMMUNICATION",
																			"MEDIA",
																			"MESSAGING",
																			"NAVIGATION",
																			"INFORMATION",
																			"SOCIAL",
																			"BACKGROUND_PROCESS",
																			"TESTING",
																			"SYSTEM",
																			"DEFAULT",
																			"COMMUNICATION",
																			"MEDIA",
																			"MESSAGING",
																			"NAVIGATION",
																			"INFORMATION",
																			"SOCIAL",
																			"BACKGROUND_PROCESS",
																			"TESTING",
																			"SYSTEM",
																			"DEFAULT",
																			"COMMUNICATION",
																			"MEDIA",
																			"MESSAGING",
																			"NAVIGATION",
																			"INFORMATION",
																			"SOCIAL",
																			"BACKGROUND_PROCESS",
																			"TESTING",
																			"SYSTEM",
																			"DEFAULT",
																			"COMMUNICATION",
																			"MEDIA",
																			"MESSAGING",
																			"NAVIGATION",
																			"INFORMATION",
																			"SOCIAL",
																			"BACKGROUND_PROCESS",
																			"TESTING",
																			"SYSTEM",
																			"DEFAULT",
																			"COMMUNICATION",
																			"MEDIA",
																			"MESSAGING",
																			"NAVIGATION",
																			"INFORMATION",
																			"SOCIAL",
																			"BACKGROUND_PROCESS",
																			"TESTING",
																			"SYSTEM",
																			"DEFAULT",
																			"COMMUNICATION",
																			"MEDIA",
																			"MESSAGING",
																			"NAVIGATION",
																			"INFORMATION",
																			"SOCIAL",
																			"BACKGROUND_PROCESS",
																			"TESTING",
																			"SYSTEM",
																			"DEFAULT",
																			"COMMUNICATION",
																			"MEDIA",
																			"MESSAGING",
																			"NAVIGATION",
																			"INFORMATION",
																			"SOCIAL",
																			"BACKGROUND_PROCESS",
																			"TESTING",
																			"SYSTEM",
																		}, 
																		appID ="01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg",
																		deviceInfo = 
																		{
																			hardware = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																			firmwareRev = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																			os = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																			osVersion = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																			carrier = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
																			maxNumberRFCOMMPorts = 100
																	}
																	
																	})

						--hmi side: expected  BasicCommunication.OnAppRegistered
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
					            {
					              	application = 
					              	{
					                	appName = "nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn",
										policyAppID = "01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg",
										hmiDisplayLanguageDesired ="EN-US",
										isMediaApplication = AppMediaType
					              	}
					            })
					 
						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
							:Timeout(2000) 

						EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

					end

				--End Test case PositiveRequestCheck.1.45

				--Begin Test case PositiveRequestCheck.1.46
				--Description: hashID: Lower bound = 1

					-- Precondition: The application should be unregistered before next test.

					function Test:UnregisterAppInterface_Success_hashIDLowerBound() 

						UnregisterApplicationSessionOne(self)
					end

					function Test:RegisterAppInterface_hashIDLowerBound() 
						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																		 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																		hashID = "a"
																	})

						--hmi side: expected  BasicCommunication.OnAppRegistered
							EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
										{
											application = 
											{
												appName = "SyncProxyTester",
												policyAppID = "123456",
												hmiDisplayLanguageDesired ="EN-US",
												isMediaApplication = AppMediaType
											}
										})

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "RESUME_FAILED"})
							:Timeout(2000)

					end

				--End Test case PositiveRequestCheck.1.46
			
			
				--Begin Test case PositiveRequestCheck.1.47
				--Description: hashID: Lower bound = 100

					-- Precondition: The application should be unregistered before next test.

					function Test:UnregisterAppInterface_Success_hashIDUpperBound() 

						UnregisterApplicationSessionOne(self)
					end

					function Test:RegisterAppInterface_hashIDUpperBound() 
						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																		 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																		hashID = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
																	})

						--hmi side: expected  BasicCommunication.OnAppRegistered
							EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
										{
											application = 
											{
												appName = "SyncProxyTester",
												policyAppID = "123456",
												hmiDisplayLanguageDesired ="EN-US",
												isMediaApplication = AppMediaType
											}
										})

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "RESUME_FAILED"})
							:Timeout(2000)

					end

				--End Test case PositiveRequestCheck.1.47
				
			--End Test case PositiveRequestCheck.1


			--Begin Test case PositiveRequestCheck.2
			--Description: escape characters and letters - chars: backslash /, slash \, quotation mark ', \b, \f, \r (SUCCESS)

				--Requirement id in JAMA: SDLAQ-CRS-358, APPLINK-8294, SDLAQ-CRS-359

				--Verification criteria: -- The request for registering was sent and executed successfully. The response code SUCCESS is returned.

				--Begin Test case PositiveRequestCheck.2.1
				--Description: appName: escape characters and letters - chars: backslash /, slash \, quotation mark ', \b, \f, \r (SUCCESS)

					-- Precondition: The application should be unregistered before next test.

					function Test:UnregisterAppInterface_Success_appNameEscChars() 

						UnregisterApplicationSessionOne(self) 
					end

					function Test:RegisterAppInterface_appNameEscChars() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ='Sync/roxy\\Tester\'\b\fSync\rProxyTester',
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
							:Timeout(2000)

						EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
					end

				--End Test case PositiveRequestCheck.2.1

				--Begin Test case PositiveRequestCheck.2.2
				--Description: ttsName: escape characters and letters - chars: backslash /, slash \, quotation mark ', \b, \f, \r (SUCCESS)

					-- Precondition: The application should be unregistered before next test.

					function Test:UnregisterAppInterface_Success_ttsNameEscChars() 

						UnregisterApplicationSessionOne(self) 
					end

					function Test:RegisterAppInterface_ttsNameEscChars() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		ttsName = 
																		{ 
																			 
																			{ 
																				text ="Back//slash",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="Slash\\",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="\'QuotationMark",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="\bSyncProxyTester",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="Sync\fProxyTester",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="\r",
																				type ="TEXT",
																			} 
																		}, 
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
							:Timeout(2000)

						EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

					end

				--End Test case PositiveRequestCheck.2.2

				--Begin Test case PositiveRequestCheck.2.3
				--Description: ngnMediaScreenAppName: escape characters and letters - chars: backslash /, slash \, quotation mark ', \b, \f, \r (SUCCESS)

					-- Precondition: The application should be unregistered before next test.

					function Test:UnregisterAppInterface_Success_ngnNameEscChars() 

						UnregisterApplicationSessionOne(self) 
					end

					function Test:RegisterAppInterface_ngnNameEscChars() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		ngnMediaScreenAppName ="S\\P\'T//aS\bP\fT\rSPT",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
							:Timeout(2000)

						EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

					end

				--End Test case PositiveRequestCheck.2.3

				--Begin Test case PositiveRequestCheck.2.4
				--Description: vrSynonyms: escape characters and letters - chars: backslash /, slash \, quotation mark ', \b, \f, \r (SUCCESS)

					-- Precondition: The application should be unregistered before next test.

					function Test:UnregisterAppInterface_Success_VRSynEscapeChars() 

						UnregisterApplicationSessionOne(self) 
					end

					function Test:RegisterAppInterface_VRSynEscapeChars() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		vrSynonyms = 
																		{ 
																			"Back//Slash",
																			"\\Slash",
																			"\'QuotationMark\'",
																			"\bSlashB",
																			"SlashF\f",
																			"SlashR\r"
																		}, 
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456"
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
							:Timeout(2000)

						EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

					end

				--End Test case PositiveRequestCheck.2.4

				--Begin Test case PositiveRequestCheck.2.5
				--Description: appID: escape characters and letters - chars: backslash /, slash \, quotation mark ', \b, \f, \r (SUCCESS)

					-- Precondition: The application should be unregistered before next test.

					function Test:UnregisterAppInterface_Success_appIDEscChars() 

						UnregisterApplicationSessionOne(self) 
					end

					function Test:RegisterAppInterface_appIDEscChars() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="Back//slash\\Slash\'QuotationMarkN\bB\fF\rRTU",
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
							:Timeout(2000)

						EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

					end

				--End Test case PositiveRequestCheck.2.5

				--Begin Test case PositiveRequestCheck.2.6
				--Description: DeviceInfo.hardware: escape characters and letters - chars: backslash /, slash \, quotation mark ', \b, \f, \r (SUCCESS)

					-- Precondition: The application should be unregistered before next test.

					function Test:UnregisterAppInterface_Success_hardwareEscChars() 

						UnregisterApplicationSessionOne(self) 
					end

					function Test:RegisterAppInterface_hardwareEscChars() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																		deviceInfo = {hardware = "Back//slash\\Slash\'QuotationMarkN\bB\fF\rRTU"}
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
							:Timeout(2000)

						EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

					end

				--End Test case PositiveRequestCheck.2.6

				--Begin Test case PositiveRequestCheck.2.7
				--Description: DeviceInfo.firmwareRev: escape characters and letters - chars: backslash /, slash \, quotation mark ', \b, \f, \r (SUCCESS)

					-- Precondition: The application should be unregistered before next test.

					function Test:UnregisterAppInterface_Success_firmwareRevEscChars() 

						UnregisterApplicationSessionOne(self) 
					end

					function Test:RegisterAppInterface_firmwareRevEscChars() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																		deviceInfo = {firmwareRev = "Back//slash\\Slash\'QuotationMarkN\bB\fF\rRTU"}
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
							:Timeout(2000)

						EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

					end

				--End Test case PositiveRequestCheck.2.7

				--Begin Test case PositiveRequestCheck.2.8
				--Description: DeviceInfo.os: escape characters and letters - chars: backslash /, slash \, quotation mark ', \b, \f, \r (SUCCESS)

					-- Precondition: The application should be unregistered before next test.

					function Test:UnregisterAppInterface_Success_osEscChars() 

						UnregisterApplicationSessionOne(self) 
					end

					function Test:RegisterAppInterface_osEscChars() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																		deviceInfo = {os = "Back//slash\\Slash\'QuotationMarkN\bB\fF\rRTU"}
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
							:Timeout(2000)

						EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

					end

				--End Test case PositiveRequestCheck.2.8

				--Begin Test case PositiveRequestCheck.2.9
				--Description: DeviceInfo.osVersion: escape characters and letters - chars: backslash /, slash \, quotation mark ', \b, \f, \r (SUCCESS)

					-- Precondition: The application should be unregistered before next test.

					function Test:UnregisterAppInterface_Success_osVersionEscChars() 

						UnregisterApplicationSessionOne(self) 
					end

					function Test:RegisterAppInterface_osVersionEscChars() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																		deviceInfo = {osVersion = "Back//slash\\Slash\'QuotationMarkN\bB\fF\rRTU"}
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
							:Timeout(2000)

						EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

					end

				--End Test case PositiveRequestCheck.2.9

				--Begin Test case PositiveRequestCheck.2.10
				--Description: DeviceInfo.carrier: escape characters and letters - chars: backslash /, slash \, quotation mark ', \b, \f, \r (SUCCESS)

					-- Precondition: The application should be unregistered before next test.

					function Test:UnregisterAppInterface_Success_carrierEscChars() 

						UnregisterApplicationSessionOne(self) 
					end

					function Test:RegisterAppInterface_carrierEscChars() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																		deviceInfo = {carrier = "Back//slash\\Slash\'QuotationMarkN\bB\fF\rRTU"}
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
							:Timeout(2000)

						EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

					end

				--End Test case PositiveRequestCheck.2.10

			--End Test case PositiveRequestCheck.2

			--Begin Test case PositiveRequestCheck.3
			--Description: Check processing request with all posible values of language in languageDesired,hmiDisplayLanguageDesired
			--Note: During SDL-HMI starting SDL should request HMI UI.GetSupportedLanguages, VR.GetSupportedLanguages, TTS.GetSupportedLanguages and HMI should respond with all languages 
			--specified in this test (added new languages which should be supported by SDL - CRQ APPLINK-13745: "NL-BE", "EL-GR", "HU-HU", "FI-FI", "SK-SK") 

				--Requirement id in JAMA: SDLAQ-CRS-358

				--Verification criteria: 

				local languageValue = {"ES-MX","FR-CA","DE-DE","ES-ES","EN-GB","RU-RU","TR-TR","PL-PL", "FR-FR","IT-IT","SV-SE","PT-PT","NL-NL", "EN-AU", "ZH-CN", "ZH-TW","JA-JP","AR-SA","KO-KR", "PT-BR","CS-CZ","DA-DK","NO-NO", "NL-BE", "EL-GR", "HU-HU", "FI-FI", "SK-SK"}
				--Begin Test case PositiveRequestCheck.3.1
				--Description: languageDesired: "EN-US","ES-MX","FR-CA","DE-DE","ES-ES","EN-GB","RU-RU","TR-TR","PL-PL",
				      -- "FR-FR","IT-IT","SV-SE","PT-PT","NL-NL", "EN_AU", "ZH_CN", "ZH-TW","JA-JP","AR-SA","KO-KR",
				      -- "PT-BR","CS-CZ","DA-DK","NO-NO", "NL-BE", "EL-GR", "HU-HU", "FI-FI", "SK-SK"

				    for i=1,#languageValue do
				    	Test["RegisterAppInterface_languageDesired_" .. tostring(languageValue[i])] = function(self)

				    		--mobile side: UnregisterAppInterface request 
							local CorIdUAI = self.mobileSession:SendRPC("UnregisterAppInterface",{}) 

							--hmi side: expect OnAppUnregistered notification 
								EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.applications["SyncProxyTester"], unexpectedDisconnect = false})
						 

							 --mobile side: UnregisterAppInterface response 
							EXPECT_RESPONSE(CorIdUAI, { success = true, resultCode = "SUCCESS"})
								:Timeout(2000)
								:Do(function(_,data)

									--mobile side: RegisterAppInterface request 
									local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																			{
																				syncMsgVersion = 
																				{ 
																					majorVersion = 2,
																					minorVersion = 2,
																				}, 
																				appName ="SyncProxyTester",
																				isMediaApplication = AppMediaType,
																				languageDesired = languageValue[i],
																				hmiDisplayLanguageDesired ="EN-US",
																				appID ="123456",
																			}) 
					 
							 		--hmi side: expected  BasicCommunication.OnAppRegistered
									EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
												            {
												              	application = 
												              	{
												                	appName = "SyncProxyTester",
																	policyAppID = "123456",
																	hmiDisplayLanguageDesired ="EN-US",
																	isMediaApplication = AppMediaType
												              	}
												            })


									--mobile side: RegisterAppInterface response 
									EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "WRONG_LANGUAGE"})
										:Timeout(2000)

									EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

								end)

				    	end
				    end

				--End Test case PositiveRequestCheck.3.1

				--Begin Test case PositiveRequestCheck.3.2
				--Description: languageDesired: "EN-US","ES-MX","FR-CA","DE-DE","ES-ES","EN-GB","RU-RU","TR-TR","PL-PL",
				      -- "FR-FR","IT-IT","SV-SE","PT-PT","NL-NL", "EN_AU", "ZH_CN", "ZH-TW","JA-JP","AR-SA","KO-KR",
				      -- "PT-BR","CS-CZ","DA-DK","NO-NO", "NL-BE", "EL-GR", "HU-HU", "FI-FI", "SK-SK"

				    for i=1,#languageValue do
				    	Test["RegisterAppInterface_hmiDisplayLanguageDesired_" .. tostring(languageValue[i])] = function(self)

				    		--mobile side: UnregisterAppInterface request 
							local CorIdUAI = self.mobileSession:SendRPC("UnregisterAppInterface",{}) 

							--hmi side: expect OnAppUnregistered notification 
								EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.applications["SyncProxyTester"], unexpectedDisconnect = false})
						 

							 --mobile side: UnregisterAppInterface response 
							EXPECT_RESPONSE(CorIdUAI, { success = true, resultCode = "SUCCESS"})
								:Timeout(2000)
								:Do(function(_,data)

									--mobile side: RegisterAppInterface request 
									local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																			{
																				syncMsgVersion = 
																				{ 
																					majorVersion = 2,
																					minorVersion = 2,
																				}, 
																				appName ="SyncProxyTester",
																				isMediaApplication = AppMediaType,
																				languageDesired = "EN-US",
																				hmiDisplayLanguageDesired = languageValue[i],
																				appID ="123456",
																			}) 
					 
							 		--hmi side: expected  BasicCommunication.OnAppRegistered
									EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
												            {
												              	application = 
												              	{
												                	appName = "SyncProxyTester",
																	policyAppID = "123456",
																	hmiDisplayLanguageDesired = languageValue[i],
																	isMediaApplication = AppMediaType
												              	}
												            })
										:Do(function(_,data)
											self.applications["SyncProxyTester"] = data.params.application.appID
										end)


									--mobile side: RegisterAppInterface response 
									EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "WRONG_LANGUAGE"})
										:Timeout(2000)

									EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

								end)

				    	end
				    end

				--End Test case PositiveRequestCheck.3.2

			--End Test case PositiveRequestCheck.3

			--Begin Test case PositiveRequestCheck.4
			--Description: Check processing request duplicate ttsName and vrSyninums

				--Requirement id in JAMA: APPLINK-7545

				--Verification criteria: 
					-- - appName(application) VRsynonyms shouldn’t be checked for uniqueness through all other registered apps VRsynonyms. The only check should be performed: appName against VRSysomyms of already registered apps.
					-- - TTSName shouldn’t be checked for uniqueness anymore.

				--Precondition:The application should be unregistered before next test.
				function Test:UnregisterAppInterface_Success_PreconditionAppRegistered() 
					UnregisterApplicationSessionOne(self) 
				end

				function Test:RegisterAppInterface_PreconditionAppRegistered() 

					--mobile side: RegisterAppInterface request 
					local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																{
																	syncMsgVersion = 
																	{ 
																		majorVersion = 2,
																		minorVersion = 2,
																	}, 
																	appName ="SyncProxyTester",
																	isMediaApplication = AppMediaType,
																	languageDesired ="EN-US",
																	hmiDisplayLanguageDesired ="EN-US",
																	appID ="123456",
																	ttsName = 
																	{ 
																		{ 
																			text ="SyncProxyTester",
																			type ="TEXT",
																		}, 
																	}, 
																	vrSynonyms = 
																	{ 
																		"VRSyncProxyTester",
																	}
																})

					--hmi side: expected  BasicCommunication.OnAppRegistered
					EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
								            {
								              	application = 
								              	{
								                	appName = "SyncProxyTester",
													policyAppID = "123456"
								              	}
								            })
						:Do(function(_,data)
							self.applications["SyncProxyTester"] = data.params.application.appID
						end)
				 

					--mobile side: RegisterAppInterface response 
					EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
						:Timeout(2000)

					EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
				end

				--Precondition Openning new session
				function Test:Case_SecondSession_ttsNameDuplicate()
				  -- Connected expectation
				  	self.mobileSession1 = mobile_session.MobileSession(
				    self,
				    self.mobileConnection)
				  	self.mobileSession1:StartService(7)
				end

			--Begin Test case PositiveRequestCheck.4.1
			--Description: duplicate ttsName (SUCCESS)

				function Test:RegisterAppInterface_ttsNameDuplicate() 

					--mobile side: RegisterAppInterface request 
					local CorIdRAI = self.mobileSession1:SendRPC("RegisterAppInterface",
																{
																	syncMsgVersion = 
																	{ 
																		majorVersion = 2,
																		minorVersion = 2,
																	}, 
																	appName ="SPT",
																	isMediaApplication = AppMediaType,
																	languageDesired ="EN-US",
																	hmiDisplayLanguageDesired ="EN-US",
																	appID ="112233",
																	ttsName = 
																	{ 
																		{ 
																			text ="SyncProxyTester",
																			type ="TEXT",
																		}, 
																	}, 
																	vrSynonyms = 
																	{ 
																		"vrSPT",
																	}
																})
					--hmi side: expected  BasicCommunication.OnAppRegistered
					EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
						:Do(function(_,data)
							self.appID2 = data.params.application.appID
						end)
				 

					--mobile side: RegisterAppInterface response 
					self.mobileSession1:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})

					EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
				end

			--End Test case PositiveRequestCheck.4.1

			--Begin Test case PositiveRequestCheck.4.1
			--Description: duplicate vrSynonyms (SUCCESS)

				--Precondition:The application should be unregistered before next test.
				function Test:UnregisterAppInterface_Success_vrSynonymsDuplicate() 
					UnregisteerApplicationSessionTwo(self) 
				end

				function Test:RegisterAppInterface_vrSynonymsDuplicate() 

					--mobile side: RegisterAppInterface request 
					local CorIdRAI = self.mobileSession1:SendRPC("RegisterAppInterface",
																{
																	syncMsgVersion = 
																	{ 
																		majorVersion = 2,
																		minorVersion = 2,
																	}, 
																	appName ="SPT",
																	isMediaApplication = AppMediaType,
																	languageDesired ="EN-US",
																	hmiDisplayLanguageDesired ="EN-US",
																	appID ="112233",
																	ttsName = 
																	{ 
																		{ 
																			text ="SPT",
																			type ="TEXT",
																		}, 
																	}, 
																	vrSynonyms = 
																	{ 
																		"VRSyncProxyTester",
																	}
																})

					--hmi side: expected  BasicCommunication.OnAppRegistered
					EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
						:Do(function(_,data)
							self.appID2 = data.params.application.appID
						end)
				 

					--mobile side: RegisterAppInterface response 
					self.mobileSession1:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})
						:Timeout(2000)

					EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
				end

			--End Test case PositiveRequestCheck.4.1


			--End Test case PositiveRequestCheck.4


		--End Test suit PositiveRequestCheck


	--=================================================================================--
	--------------------------------Positive response check------------------------------
	--=================================================================================--

		-- Note: Response parameters will be tested in SetDisplayLayout script





----------------------------------------------------------------------------------------------
----------------------------------------III TEST BLOCK----------------------------------------
----------------------------------------Negative cases----------------------------------------
----------------------------------------------------------------------------------------------

	--=================================================================================--
	---------------------------------Negative request check------------------------------
	--=================================================================================--

		--Begin Test suit NegativeRequestCheck
		--Description: check of each request parameter value out of bound, with wrong type, empty, duplicate etc.
				-- - syncMsgVersion
					-- - major version type="Integer" minvalue="1" maxvalue="10"
					-- - minor version type="Integer" minvalue="0" maxvalue="1000">
				-- - appName type="String" maxlength="100"
				-- - isMediaApplication type="Boolean"
				-- - appID type="String" maxlength="100"
				-- - ttsName type="TTSChunk" minsize="1" maxsize="100" array="true"
				-- - ngnMediaScreenAppName type="String" maxlength="100"
				-- - vrSynonyms type="String" maxlength="40" minsize="1" maxsize="100" array="true"
				-- - appHMIType type="AppHMIType" minsize="1" maxsize="100" array="true"
							-- AppHMIType: DEFAULT, COMMUNICATION, MEDIA, MESSAGING, NAVIGATION, INFORMATION, SOCIAL, 
							-- BACKGROUND_PROCESS, TESTING, SYSTEM
				-- - languageDesired type="Language"
				-- - hmiDisplayLanguageDesired type="Language"
				-- - hashID type="String" maxlength="100"
				-- - deviceInfo
					-- - hardware type="String" minlength="0" maxlength="500"
					-- - firmwareRev type="String" minlength="0" maxlength="500"
					-- - os type="String" minlength="0" maxlength="500"
					-- - osVersion type="String" minlength="0" maxlength="500"
					-- - carrier type="String" minlength="0" maxlength="500"
					-- - maxNumberRFCOMMPorts type="Integer" minvalue="0" maxvalue="100"

			--Begin Test case NegativeRequestCheck.1
			--Description: Check processing request with out bound values


				--Requirement id in JAMA: SDLAQ-CRS-3, 
					-- SDLAQ-CRS-1316, 
					-- SDLAQ-CRS-1317,
					-- SDLAQ-CRS-2753,
					-- SDLAQ-CRS-2910


				--Verification criteria:
					--[[- SyncMsgVersion which contains majorVersion more than 10 or less than 1 returns INVALID_DATA in the responses.
					- SyncMsgVersion which contains minorVersion more than 1000 or less than 0 returns INVALID_DATA in the responses.]]

					-- AppHMITypes different from DEFAULT, COMMUNICATION, MEDIA, MESSAGING, NAVIGATION, INFORMATION, SOCIAL, BACKGROUND_PROCESS, TESTING and SYSTEM are processed by RegisterAppInterface with INVALID_DATA in response resultCode

					--[[- The request with "syncMsgVersion" value out of bounds is sent, the response comes with »INVALID_DATA» result code.
					- The request with "appName" value out of bounds is sent, the response comes with »INVALID_DATA» result code.
					- The request with "ttsName" array out of bounds is sent, the response comes with «INVALID_DATA» result code.
					- The request with empty "ttsName" array is sent, the response comes with «INVALID_DATA» result code.
					- The request with "ngnMediaScreenAppName" value out of bounds is sent, the response comes with «INVALID_DATA» result code.
					- The request with "syncMsgVersion" value out of bounds is sent, the response comes with «INVALID_DATA» result code.
					- The request with "vrSynonyms" array out of bounds is sent, the response comes with «INVALID_DATA» result code.
					- The request with "vrSynonyms" value out of bounds is sent, the response comes with «INVALID_DATA» result code.
					- The request with "TTSChunk" value out of upper bounds is sent, the response comes with «INVALID_DATA» result code.
					- The request with "languageDesired" parameter of enum range is sent, the response comes with «INVALID_DATA» result code.
					- The request with "hmiDisplayLanguageDesired" parameter of enum range is sent, the response comes with «INVALID_DATA» result code.]]

					-- In case the mobile application sends any RPC with 'text:"  "' (whitespace(s)) of 'ttsChunk' struct and other valid params, SDL must consider such RPC as invalid , not transfer it to HMI and respond with INVALID_DATA result code + success:false.

				--Begin Test case NegativeRequestCheck.1.1
				--Description: majorVersion is out of lower bound

					-- Precondition: The application should be unregistered before next test.
					function Test:UnregisterAppInterface_Success_SyncMsgVerMajorOutLowerBound() 
						UnregisterApplicationSessionOne(self) 
					end

					function Test:RegisterAppInterface_SyncMsgVerMajorOutLowerBound() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 0,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)	

				 	end 	

				--End Test case NegativeRequestCheck.1.1

				--Begin Test case NegativeRequestCheck.1.2
				--Description: SyncMsgVersion: minorVersion is out of lower bound

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_SyncMsgVerMinorOutLowerBound()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_SyncMsgVerMinorOutLowerBound() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = -1,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case NegativeRequestCheck.1.2

				--Begin Test case NegativeRequestCheck.1.3
				--Description: SyncMsgVersion: majorVersion is out of upper bound

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_SyncMsgVerMajorOutUpperBound()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_SyncMsgVerMajorOutUpperBound() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 11,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case NegativeRequestCheck.1.3


				--Begin Test case NegativeRequestCheck.1.4
				--Description: SyncMsgVersion: minorVersion is out of upper bound

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_SyncMsgVerMinorOutUpperBound()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_SyncMsgVerMinorOutUpperBound() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 1001,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case NegativeRequestCheck.1.4


				--Begin Test case NegativeRequestCheck.1.5
				--Description: appName: out of loewer bound = empty

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_appNameEmpty()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_appNameEmpty() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case NegativeRequestCheck.1.5

				--Begin Test case NegativeRequestCheck.1.6
				--Description: appName: out of upper bound = 101

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_appNameOutUpperBound()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_appNameOutUpperBound() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfghi",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)

					end

				--End Test case NegativeRequestCheck.1.6

				--Begin Test case NegativeRequestCheck.1.7
				--Description: ttsName: Array out of lower bound

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_ttsNameArrayEmpty()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_ttsNameArrayEmpty() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		ttsName = 
																		{ 
																		}, 
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case NegativeRequestCheck.1.7

				--Begin Test case NegativeRequestCheck.1.8
				--Description: ttsName: Array out of upper bound

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_ttsNameArrayOutUpperBound()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_ttsNameArrayOutUpperBound() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		ttsName = 
																		{ 
																			 
																			{ 
																				text ="SyncProxyTester1",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester2",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester3",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester4",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester5",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester6",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester7",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester8",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester9",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester10",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester11",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester12",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester13",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester14",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester15",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester16",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester17",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester18",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester19",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester20",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester21",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester22",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester23",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester24",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester25",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester26",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester27",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester28",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester29",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester30",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester31",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester32",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester33",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester34",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester35",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester36",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester37",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester38",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester39",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester40",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester41",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester42",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester43",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester44",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester45",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester46",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester47",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester48",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester49",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester50",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester51",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester52",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester53",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester54",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester55",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester56",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester57",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester58",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester59",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester60",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester61",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester62",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester63",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester64",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester65",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester66",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester67",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester68",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester69",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester70",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester71",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester72",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester73",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester74",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester75",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester76",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester77",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester78",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester79",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester80",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester81",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester82",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester83",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester84",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester85",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester86",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester87",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester88",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester89",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester90",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester91",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester92",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester93",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester94",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester95",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester96",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester97",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester98",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester99",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester100",
																				type ="TEXT",
																			}, 
																			 
																			{ 
																				text ="SyncProxyTester101",
																				type ="TEXT",
																			}, 
																		}, 
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 
						 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case NegativeRequestCheck.1.8

				--Begin Test case NegativeRequestCheck.1.9
				--Description: text out upper bound = 501

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_ttsNameTextOutUpperBound()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_ttsNameTextOutUpperBound() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		ttsName = 
																		{ 
																			 
																			{ 
																				text ="01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfghijklm",
																				type ="TEXT",
																			}, 
																		}, 
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case NegativeRequestCheck.1.9

				--Begin Test case NegativeRequestCheck.1.10
				--Description: ngnMediaScreenAppName:  out lower bound (empty)

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_ngnNameEmpty()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_ngnNameEmpty() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		ngnMediaScreenAppName ="",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case NegativeRequestCheck.1.10

				--Begin Test case NegativeRequestCheck.1.11
				--Description: ngnMediaScreenAppName: out upper bound

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_ngnNameOutUpperBound()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_ngnNameOutUpperBound() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		ngnMediaScreenAppName ="01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfghi",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case NegativeRequestCheck.1.11

				--Begin Test case NegativeRequestCheck.1.12
				--Description: vrSynonyms: Array out lower bound (empty)

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_VRSynArrayEmpty()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_VRSynArrayEmpty() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		vrSynonyms = 
																		{ 
																		}, 
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case NegativeRequestCheck.1.12

				--Begin Test case NegativeRequestCheck.1.13
				--Description: vrSynonyms: Array out upper bound = 101

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_VRSynArrayOutUpperBound()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_VRSynArrayOutUpperBound() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		vrSynonyms = 
																		{ 
																			"VRSyncProxyTester1",
																			"VRSyncProxyTester2",
																			"VRSyncProxyTester3",
																			"VRSyncProxyTester4",
																			"VRSyncProxyTester5",
																			"VRSyncProxyTester6",
																			"VRSyncProxyTester7",
																			"VRSyncProxyTester8",
																			"VRSyncProxyTester9",
																			"VRSyncProxyTester10",
																			"VRSyncProxyTester11",
																			"VRSyncProxyTester12",
																			"VRSyncProxyTester13",
																			"VRSyncProxyTester14",
																			"VRSyncProxyTester15",
																			"VRSyncProxyTester16",
																			"VRSyncProxyTester17",
																			"VRSyncProxyTester18",
																			"VRSyncProxyTester19",
																			"VRSyncProxyTester20",
																			"VRSyncProxyTester21",
																			"VRSyncProxyTester22",
																			"VRSyncProxyTester23",
																			"VRSyncProxyTester24",
																			"VRSyncProxyTester25",
																			"VRSyncProxyTester26",
																			"VRSyncProxyTester27",
																			"VRSyncProxyTester28",
																			"VRSyncProxyTester29",
																			"VRSyncProxyTester30",
																			"VRSyncProxyTester31",
																			"VRSyncProxyTester32",
																			"VRSyncProxyTester33",
																			"VRSyncProxyTester34",
																			"VRSyncProxyTester35",
																			"VRSyncProxyTester36",
																			"VRSyncProxyTester37",
																			"VRSyncProxyTester38",
																			"VRSyncProxyTester39",
																			"VRSyncProxyTester40",
																			"VRSyncProxyTester41",
																			"VRSyncProxyTester42",
																			"VRSyncProxyTester43",
																			"VRSyncProxyTester44",
																			"VRSyncProxyTester45",
																			"VRSyncProxyTester46",
																			"VRSyncProxyTester47",
																			"VRSyncProxyTester48",
																			"VRSyncProxyTester49",
																			"VRSyncProxyTester50",
																			"VRSyncProxyTester51",
																			"VRSyncProxyTester52",
																			"VRSyncProxyTester53",
																			"VRSyncProxyTester54",
																			"VRSyncProxyTester55",
																			"VRSyncProxyTester56",
																			"VRSyncProxyTester57",
																			"VRSyncProxyTester58",
																			"VRSyncProxyTester59",
																			"VRSyncProxyTester60",
																			"VRSyncProxyTester61",
																			"VRSyncProxyTester62",
																			"VRSyncProxyTester63",
																			"VRSyncProxyTester64",
																			"VRSyncProxyTester65",
																			"VRSyncProxyTester66",
																			"VRSyncProxyTester67",
																			"VRSyncProxyTester68",
																			"VRSyncProxyTester69",
																			"VRSyncProxyTester70",
																			"VRSyncProxyTester71",
																			"VRSyncProxyTester72",
																			"VRSyncProxyTester73",
																			"VRSyncProxyTester74",
																			"VRSyncProxyTester75",
																			"VRSyncProxyTester76",
																			"VRSyncProxyTester77",
																			"VRSyncProxyTester78",
																			"VRSyncProxyTester79",
																			"VRSyncProxyTester80",
																			"VRSyncProxyTester81",
																			"VRSyncProxyTester82",
																			"VRSyncProxyTester83",
																			"VRSyncProxyTester84",
																			"VRSyncProxyTester85",
																			"VRSyncProxyTester86",
																			"VRSyncProxyTester87",
																			"VRSyncProxyTester88",
																			"VRSyncProxyTester89",
																			"VRSyncProxyTester90",
																			"VRSyncProxyTester91",
																			"VRSyncProxyTester92",
																			"VRSyncProxyTester93",
																			"VRSyncProxyTester94",
																			"VRSyncProxyTester95",
																			"VRSyncProxyTester96",
																			"VRSyncProxyTester97",
																			"VRSyncProxyTester98",
																			"VRSyncProxyTester99",
																			"VRSyncProxyTester100",
																			"VRSyncProxyTester101",
																		}, 
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case NegativeRequestCheck.1.13

				--Begin Test case NegativeRequestCheck.1.14
				--Description:  vrSynonyms: synonym out lower bound (empty)

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_VRSynEmpty()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_VRSynEmpty() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		vrSynonyms = 
																		{ 
																			"",
																		}, 
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case NegativeRequestCheck.1.14

				--Begin Test case NegativeRequestCheck.1.15
				--Description: rSynonyms: synonym out upper bound

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_VRSynOutUpperBound()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_VRSynOutUpperBound() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		vrSynonyms = 
																		{ 
																			"01234567890abcdASDF!@#$%^*()-_+|~{}[]:,AB",
																		}, 
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case NegativeRequestCheck.1.15

				--Begin Test case NegativeRequestCheck.1.16
				--Description: appHMIType: Array out lower bound (empty)

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_appHMITypeArrayEmpty()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_appHMITypeArrayEmpty() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appHMIType = 
																		{ 
																		}, 
																		appID ="123456",
																	
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case NegativeRequestCheck.1.16

				--Begin Test case NegativeRequestCheck.1.17
				--Description: appHMIType: Array out upper bound = 101

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_appHMITypeArrayOutUpperBound()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_appHMITypeArrayOutUpperBound() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appHMIType = 
																		{ 
																			"DEFAULT",
																			"COMMUNICATION",
																			"MEDIA",
																			"MESSAGING",
																			"NAVIGATION",
																			"INFORMATION",
																			"SOCIAL",
																			"BACKGROUND_PROCESS",
																			"TESTING",
																			"SYSTEM",
																			"DEFAULT",
																			"COMMUNICATION",
																			"MEDIA",
																			"MESSAGING",
																			"NAVIGATION",
																			"INFORMATION",
																			"SOCIAL",
																			"BACKGROUND_PROCESS",
																			"TESTING",
																			"SYSTEM",
																			"DEFAULT",
																			"COMMUNICATION",
																			"MEDIA",
																			"MESSAGING",
																			"NAVIGATION",
																			"INFORMATION",
																			"SOCIAL",
																			"BACKGROUND_PROCESS",
																			"TESTING",
																			"SYSTEM",
																			"DEFAULT",
																			"COMMUNICATION",
																			"MEDIA",
																			"MESSAGING",
																			"NAVIGATION",
																			"INFORMATION",
																			"SOCIAL",
																			"BACKGROUND_PROCESS",
																			"TESTING",
																			"SYSTEM",
																			"DEFAULT",
																			"COMMUNICATION",
																			"MEDIA",
																			"MESSAGING",
																			"NAVIGATION",
																			"INFORMATION",
																			"SOCIAL",
																			"BACKGROUND_PROCESS",
																			"TESTING",
																			"SYSTEM",
																			"DEFAULT",
																			"COMMUNICATION",
																			"MEDIA",
																			"MESSAGING",
																			"NAVIGATION",
																			"INFORMATION",
																			"SOCIAL",
																			"BACKGROUND_PROCESS",
																			"TESTING",
																			"SYSTEM",
																			"DEFAULT",
																			"COMMUNICATION",
																			"MEDIA",
																			"MESSAGING",
																			"NAVIGATION",
																			"INFORMATION",
																			"SOCIAL",
																			"BACKGROUND_PROCESS",
																			"TESTING",
																			"SYSTEM",
																			"DEFAULT",
																			"COMMUNICATION",
																			"MEDIA",
																			"MESSAGING",
																			"NAVIGATION",
																			"INFORMATION",
																			"SOCIAL",
																			"BACKGROUND_PROCESS",
																			"TESTING",
																			"SYSTEM",
																			"DEFAULT",
																			"COMMUNICATION",
																			"MEDIA",
																			"MESSAGING",
																			"NAVIGATION",
																			"INFORMATION",
																			"SOCIAL",
																			"BACKGROUND_PROCESS",
																			"TESTING",
																			"SYSTEM",
																			"DEFAULT",
																			"COMMUNICATION",
																			"MEDIA",
																			"MESSAGING",
																			"NAVIGATION",
																			"INFORMATION",
																			"SOCIAL",
																			"BACKGROUND_PROCESS",
																			"TESTING",
																			"SYSTEM",
																			"SYSTEM",
																		}, 
																		appID ="123456",
																	
																	}) 
																 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case NegativeRequestCheck.1.17

				--Begin Test case NegativeRequestCheck.1.18
				--Description: appID: out lower bound (empty)

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_appIDEmpty()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_appIDEmpty() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="",
																	
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case NegativeRequestCheck.1.18

				--Begin Test case NegativeRequestCheck.1.19
				--Description: appID: out upper bound = 101

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_appIDOutUpperBound()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_appIDOutUpperBound() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
							{
							  	 
								syncMsgVersion = 
								{ 
									majorVersion = 2,
									minorVersion = 2,
								}, 
								appName ="SyncProxyTester",
								isMediaApplication = AppMediaType,
								languageDesired ="EN-US",
								hmiDisplayLanguageDesired ="EN-US",
								appID ="01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfghi",
							
							}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case NegativeRequestCheck.1.19

				--Begin Test case NegativeRequestCheck.1.20
				--Description: hashID: out lower bound (empty)

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_hashIDEmpty()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_hashIDEmpty() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID = "123456",
																		hashID = ""
																	
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case NegativeRequestCheck.1.20

				--Begin Test case NegativeRequestCheck.1.21
				--Description: hashID: out upper bound = 101

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_hashIDOutUpperBound()
						OpenConnectionCreateSession(self)
					end					

					function Test:RegisterAppInterface_hashIDOutUpperBound() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID = "123456",
																		hashID = "01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfghi"
																	
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case NegativeRequestCheck.1.21

				--Begin Test case NegativeRequestCheck.1.22
				--Description: deviceInfo.hardware: out upper bound

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_hardwareOutUpperBound()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_hardwareOutUpperBound() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID = "123456",
																		deviceInfo = 
																		{
																			hardware = "01234567890abcdeghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg0123456"
																		}
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case NegativeRequestCheck.1.22

				--Begin Test case NegativeRequestCheck.1.23
				--Description: deviceInfo.firmwareRev: out upper bound

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_firmwareRevOutUpperBound()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_firmwareRevOutUpperBound() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID = "123456",
																		deviceInfo = 
																		{
																			firmwareRev = "01234567890abcdeghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg0123456"
																		}
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end 

				--End Test case NegativeRequestCheck.1.23

				--Begin Test case NegativeRequestCheck.1.24
				--Description: deviceInfo.os: out upper bound

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_osOutUpperBound()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_osOutUpperBound() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID = "123456",
																		deviceInfo = 
																		{
																			os = "01234567890abcdeghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg0123456"
																		}
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case NegativeRequestCheck.1.24

				--Begin Test case NegativeRequestCheck.1.25
				--Description: deviceInfo.osVersion: out upper bound

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_osVersionOutUpperBound()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_osVersionOutUpperBound() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID = "123456",
																		deviceInfo = 
																		{
																			osVersion = "01234567890abcdeghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg0123456"
																		}
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case NegativeRequestCheck.1.25

				--Begin Test case NegativeRequestCheck.1.26
				--Description: deviceInfo.carrier: out upper bound

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_carrierOutUpperBound()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_carrierOutUpperBound() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID = "123456",
																		deviceInfo = 
																		{
																			carrier = "01234567890abcdeghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg0123456"
																		}
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case NegativeRequestCheck.1.26

				--Begin Test case NegativeRequestCheck.1.27
				--Description: deviceInfo.maxNumberRFCOMMPorts: out lower bound

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_maxNumberRFCOMMPortsOutLowerBound()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_maxNumberRFCOMMPortsOutLowerBound() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID = "123456",
																		deviceInfo = 
																		{
																			maxNumberRFCOMMPorts = -1
																		}
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case NegativeRequestCheck.1.27

				--Begin Test case NegativeRequestCheck.1.28
				--Description: deviceInfo.maxNumberRFCOMMPorts: out upper bound

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_maxNumberRFCOMMPortsOutUpperBound()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_maxNumberRFCOMMPortsOutUpperBound() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID = "123456",
																		deviceInfo = 
																		{
																			maxNumberRFCOMMPorts = 101
																		}
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case NegativeRequestCheck.1.28

				
			--End Test case NegativeRequestCheck.1

			--Begin Test case NegativeRequestCheck.2
			--Description: Check processing request with wrong type os parameters

				--Requirement id in JAMA: SDLAQ-CRS-3
					-- SDLAQ-CRS-2753
					-- SDLAQ-CRS-359


				--Verification criteria:
					--[[ --Parameter provided with wrong type
					- The request with wrong type of parameter is sent, the response comes with «INVALID_DATA» result code.]]

				--Begin Test case NegativeRequestCheck.2.1
				--Description: appName: wrong type

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_appNameWrongType()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_appNameWrongType() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName = 123,
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case NegativeRequestCheck.2.1

				--Begin Test case NegativeRequestCheck.2.2
				--Description: ngnMediaScreenAppName: wrong type

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_ngnNameWrongType()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_ngnNameWrongType() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		ngnMediaScreenAppName = 123,
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case NegativeRequestCheck.2.2

				--Begin Test case NegativeRequestCheck.2.3
				--Description: hashID: wrong type

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_hashIDWrongType()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_hashIDWrongType() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID = "123456",
																		hashID = 123
																	
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case NegativeRequestCheck.2.3

				--Begin Test case NegativeRequestCheck.2.4
				--Description: vrSynonyms: synonym element wrong type

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_VRSynElementWrongType()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_VRSynElementWrongType() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		vrSynonyms = 
																		{ 
																			123,
																		}, 
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case NegativeRequestCheck.2.4

				--Begin Test case NegativeRequestCheck.2.4
				--Description: vrSynonyms: synonym wrong type

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_VRSynWrongType()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_VRSynWrongType() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		vrSynonyms = 123,
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case NegativeRequestCheck.2.4

				--Begin Test case NegativeRequestCheck.2.5
				--Description: isMediaApplication: wrong type

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_isMediaWrongType()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_isMediaWrongType() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = "true",
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case NegativeRequestCheck.2.5

				--Begin Test case NegativeRequestCheck.2.6
				--Description: appID: wrong type 

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_appIDWrongType()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_appIDWrongType() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID = 123,
																	
																	}) 
						 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case NegativeRequestCheck.2.6

				--Begin Test case NegativeRequestCheck.2.7
				--Description: SyncMsgVersion.majorVersion: wrong type 

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_SyncMsgVerWrongMajorType()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_SyncMsgVerWrongMajorType() 

	 					--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion ="2",
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 
 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case NegativeRequestCheck.2.7

				--Begin Test case NegativeRequestCheck.2.8
				--Description: SyncMsgVersion.minorVersion: wrong type

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_SyncMsgVerWrongMinorType()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_SyncMsgVerWrongMinorType() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion ="2",
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case NegativeRequestCheck.2.8

				--Begin Test case NegativeRequestCheck.2.9
				--Description: SyncMsgVersion: wrong type

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_SyncMsgVerWrongType()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_SyncMsgVerWrongType() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 123, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case NegativeRequestCheck.2.9

				--Begin Test case NegativeRequestCheck.2.10
				--Description: ttsName.text: wrong type

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_ttsNameTextWrongType()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_ttsNameTextWrongType() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		ttsName = 
																		{ 
																			 
																			{ 
																				text = 123,
																				type ="TEXT",
																			}, 
																		}, 
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case NegativeRequestCheck.2.10

				--Begin Test case NegativeRequestCheck.2.11
				--Description: ttsName.type: wrong type

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_ttsNameTypeWrongType()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_ttsNameTypeWrongType() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		ttsName = 
																		{ 
																			 
																			{ 
																				text = "ttsName",
																				type = true,
																			}, 
																		}, 
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case NegativeRequestCheck.2.11

				--Begin Test case NegativeRequestCheck.2.12
				--Description: ttsName element: wrong type

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_ttsNameElementWrongType()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_ttsNameElementWrongType() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		ttsName = 
																		{ 
																			 
																			"ttsName"
																		}, 
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case NegativeRequestCheck.2.12

				--Begin Test case NegativeRequestCheck.2.13
				--Description: ttsName: wrong type

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_ttsNameWrongType()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_ttsNameWrongType() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		ttsName = true, 
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case NegativeRequestCheck.2.13

				--Begin Test case NegativeRequestCheck.2.14
				--Description: languageDesired : wrong type

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_languageDesiredWrongType()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_languageDesiredWrongType() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired = 123,
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case NegativeRequestCheck.2.14

				--Begin Test case NegativeRequestCheck.2.15
				--Description: hmiDisplayLanguageDesired: wrong type

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_hmiDisplayLanguageDesiredWrongType()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_hmiDisplayLanguageDesiredWrongType() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired = "EN-US",
																		hmiDisplayLanguageDesired = 123,
																		appID ="123456",
																	
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case NegativeRequestCheck.2.15

				--Begin Test case NegativeRequestCheck.2.16
				--Description: appHMIType element: wrong type

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_appHMITypeElementWrongType()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_appHMITypeElementWrongType() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired = "EN-US",
																		hmiDisplayLanguageDesired = "EN-US",
																		appHMIType = { 123 },
																		appID ="123456",
																	
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case NegativeRequestCheck.2.16

				--Begin Test case NegativeRequestCheck.2.17
				--Description: appHMIType: wrong type

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_appHMITypeWrongType()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_appHMITypeWrongType() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired = "EN-US",
																		hmiDisplayLanguageDesired = "EN-US",
																		appHMIType = 123,
																		appID ="123456",
																	
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case NegativeRequestCheck.2.17

				--Begin Test case NegativeRequestCheck.2.18
				--Description: deviceInfo.hardware: wrong type

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_hardwareWrongType()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_hardwareWrongType() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID = "123456",
																		deviceInfo = 
																		{
																			hardware = 123
																		}
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case NegativeRequestCheck.2.18

				--Begin Test case NegativeRequestCheck.2.19
				--Description: deviceInfo.firmwareRev: wrong type

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_firmwareRevWrongType()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_firmwareRevWrongType() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID = "123456",
																		deviceInfo = 
																		{
																			firmwareRev = 123
																		}
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case NegativeRequestCheck.2.19

				--Begin Test case NegativeRequestCheck.2.20
				--Description: deviceInfo.os: wrong type

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_osWrongType()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_osWrongType() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID = "123456",
																		deviceInfo = 
																		{
																			os = 123
																		}
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case NegativeRequestCheck.2.20

				--Begin Test case NegativeRequestCheck.2.21
				--Description: deviceInfo.osVersion: wrong type

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_osVersionWrongType()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_osVersionWrongType() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID = "123456",
																		deviceInfo = 
																		{
																			osVersion = 123
																		}
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case NegativeRequestCheck.2.21

				--Begin Test case NegativeRequestCheck.2.22
				--Description: deviceInfo.carrier: wrong type

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_carrierWrongType()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_carrierWrongType() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID = "123456",
																		deviceInfo = 
																		{
																			carrier = 123
																		}
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case NegativeRequestCheck.2.22

				--Begin Test case NegativeRequestCheck.2.23
				--Description: deviceInfo.maxNumberRFCOMMPorts: wrong type

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_maxNumberRFCOMMPortsWrongType()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_maxNumberRFCOMMPortsWrongType() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID = "123456",
																		deviceInfo = 
																		{
																			maxNumberRFCOMMPorts = "123"
																		}
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case NegativeRequestCheck.2.23

				--Begin Test case NegativeRequestCheck.2.24
				--Description: deviceInfo: wrong type

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_deviceInfoWrongType()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_deviceInfoWrongType() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID = "123456",
																		deviceInfo =  123
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case NegativeRequestCheck.2.24

			--End Test case NegativeRequestCheck.2

			--Begin Test case NegativeRequestCheck.3
			--Description: Check processing request with empty values

				--Requirement id in JAMA: 
					--SDLAQ-CRS-359

				--Verification criteria:
					--[[- The request with empty string, array in parameter is sent, the response comes with «INVALID_DATA» result code.]]

				--Begin Test case NegativeRequestCheck.3.1
				--Description: languageDesired: is empty value

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_langDesEmpty()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_langDesEmpty() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case NegativeRequestCheck.3.1

				--Begin Test case NegativeRequestCheck.3.2
				--Description: syncMsgVersion: Tag is empty

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_syncMsgVersionTagEmpty()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_syncMsgVersionTagEmpty() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																		syncMsgVersion = {}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case NegativeRequestCheck.3.2

				--Begin Test case NegativeRequestCheck.3.3
				--Description:ttsName: TTSChunk is empty

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_ttsNameTTSChunkEmpty()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_ttsNameTTSChunkEmpty() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		ttsName = 
																		{ 
																			 
																			{ 
																			}, 
																		}, 
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case NegativeRequestCheck.3.3

				--Begin Test case NegativeRequestCheck.3.4
				--Description: ttsName: type is empty

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_ttsNameTypeEmpty()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_ttsNameTypeEmpty() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		ttsName = 
																		{ 
																			 
																			{ 
																				text ="SyncProxyTester",
																				type ="",
																			}, 
																		}, 
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case NegativeRequestCheck.3.4

				--Begin Test case NegativeRequestCheck.3.5
				--Description: hmiDisplayLanguageDesired: is empty value

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_hmiDisplayLangEmpty()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_hmiDisplayLangEmpty() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="",
																		appID ="123456",
																	
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case NegativeRequestCheck.3.5

				--Begin Test case NegativeRequestCheck.3.6
				--Description: appHMIType: is empty value

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_appHMITypeEmpty()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_appHMITypeEmpty() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appHMIType = 
																		{ 
																			"",
																		}, 
																		appID ="123456",
																	
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case NegativeRequestCheck.3.6

			--End Test case NegativeRequestCheck.3

			--Begin Test case NegativeRequestCheck.4
			--Description: Check processing requests with '\n' and-or '\t' and-or 'whitespace'-as-the-only-symbol(s) in  parameters

				--Requirement id in JAMA: SDLAQ-CRS-3,
					--SDLAQ-CRS-359

				--Verification criteria:
					--[[- SDL responds with INVALID_DATA resultCode in case RegisterAppInterface request comes with '\n' and-or '\t' and-or 'whitespace'-as-the-only-symbol(s) in "text" parameter of "TTSChunk" struct.
					- SDL responds with INVALID_DATA resultCode in case RegisterAppInterface request comes with '\n' and-or '\t' and-or 'whitespace'-as-the-only-symbol(s) in "appName" parameter
					- SDL responds with INVALID_DATA resultCode in case RegisterAppInterface request comes with '\n' and-or '\t' and-or 'whitespace'-as-the-only-symbol(s) in "ngnMediaScreenAppName" parameter
					- SDL responds with INVALID_DATA resultCode in case RegisterAppInterface request comes with '\n' and-or '\t' and-or 'whitespace'-as-the-only-symbol(s) in "vrSynonyms" parameter
					- SDL responds with INVALID_DATA resultCode in case RegisterAppInterface request comes with '\n' and-or '\t' and-or 'whitespace'-as-the-only-symbol(s) in "hashID" parameter
					- SDL responds with INVALID_DATA resultCode in case RegisterAppInterface request comes with '\n' and-or '\t' and-or 'whitespace'-as-the-only-symbol(s) in "hardware" parameter of deviceInfo struct
					- SDL responds with INVALID_DATA resultCode in case RegisterAppInterface request comes with '\n' and-or '\t' and-or 'whitespace'-as-the-only-symbol(s) in "firmwareRev" parameter of deviceInfo struct
					- SDL responds with INVALID_DATA resultCode in case RegisterAppInterface request comes with '\n' and-or '\t' and-or 'whitespace'-as-the-only-symbol(s) in "os" parameter of deviceInfo struct
					- SDL responds with INVALID_DATA resultCode in case RegisterAppInterface request comes with '\n' and-or '\t' and-or 'whitespace'-as-the-only-symbol(s) in "osVersion" parameter of deviceInfo struct
					- SDL responds with INVALID_DATA resultCode in case RegisterAppInterface request comes with '\n' and-or '\t' and-or 'whitespace'-as-the-only-symbol(s) in "carrier" parameter of deviceInfo struct
					-. SDL responds with INVALID_DATA resultCode in case RegisterAppInterface request comes with '\n' and-or '\t' and-or 'whitespace'-as-the-only-symbol(s) in "appID" parameter
					]]

				--Begin Test case NegativeRequestCheck.4.1
				--Description: appName: Escape sequence \n

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_appNameNewLineChar()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_appNameNewLineChar() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncSync\nTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 
						 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)

					end

				--End Test case NegativeRequestCheck.4.1

				--Begin Test case NegativeRequestCheck.4.2
				--Description: appName: Escape sequence \t

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_appNameTabChar()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_appNameTabChar() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncSync\tTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 
						 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)

					end

				--End Test case NegativeRequestCheck.4.2

				--Begin Test case NegativeRequestCheck.4.3
				--Description: appName: Only whitespaces

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_appNameWhitespace()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_appNameWhitespace() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName = "        ",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 
						 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)

					end

				--End Test case NegativeRequestCheck.4.3

				--Begin Test case NegativeRequestCheck.4.4
				--Description: ttsName.text: Escape sequence \n

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_ttsNameTextNewLineChar()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_ttsNameTextNewLineChar() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																		ttsName = {{text = "Tes\nter" , type = "TEXT"}}
																	}) 
						 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)

					end

				--End Test case NegativeRequestCheck.4.4

				--Begin Test case NegativeRequestCheck.4.5
				--Description: ttsName.text: Escape sequence \t

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_ttsNameTextTabChar()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_ttsNameTextTabChar() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																		ttsName = {{text = "Tes\tter" , type = "TEXT"}}
																	}) 
						 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)

					end

				--End Test case NegativeRequestCheck.4.5

				--Begin Test case NegativeRequestCheck.4.6
				--Description: ttsName.text: Only whitespaces

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_ttsNameTextWhitespace()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_ttsNameTextWhitespace()

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																		ttsName = {{text = "        " , type = "TEXT"}}
																	}) 
						 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)

					end

				--End Test case NegativeRequestCheck.4.6

				--Begin Test case NegativeRequestCheck.4.7
				--Description: ngnMediaScreenAppName: Escape sequence \n

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_ngnMediaScreenAppNameNewLineChar()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_ngnMediaScreenAppNameNewLineChar() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																		ngnMediaScreenAppName = "SP\nT"
																	}) 
						 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)

					end

				--End Test case NegativeRequestCheck.4.7

				--Begin Test case NegativeRequestCheck.4.8
				--Description: ngnMediaScreenAppName: Escape sequence \t

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_ngnMediaScreenAppNameTabChar()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_ngnMediaScreenAppNameTabChar() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																		ngnMediaScreenAppName = "SP\tT"
																	}) 
						 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)

					end

				--End Test case NegativeRequestCheck.4.8

				--Begin Test case NegativeRequestCheck.4.9
				--Description: ngnMediaScreenAppName: Only whitespaces

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_ngnMediaScreenAppNameWhitespace()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_ngnMediaScreenAppNameWhitespace() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																		ngnMediaScreenAppName = "        "
																	}) 
						 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)

					end

				--End Test case NegativeRequestCheck.4.9

				--Begin Test case NegativeRequestCheck.4.10
				--Description: vrSynonyms: Escape sequence \n

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_vrSynonymsNewLineChar()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_vrSynonymsNewLineChar() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																		vrSynonyms = {"Tes\nter"}
																	}) 
						 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)

					end

				--End Test case NegativeRequestCheck.4.10

				--Begin Test case NegativeRequestCheck.4.11
				--Description: vrSynonyms: Escape sequence \t

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_vrSynonymsTabChar()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_vrSynonymsTabChar() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																		vrSynonyms = {"Tes\tter"}
																	}) 
						 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)

					end

				--End Test case NegativeRequestCheck.4.11

				--Begin Test case NegativeRequestCheck.4.12
				--Description: vrSynonyms: Only whitespace

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_vrSynonymsWhitespace()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_vrSynonymsWhitespace() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																		vrSynonyms = {"        "}
																	}) 
						 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)

					end

				--End Test case NegativeRequestCheck.4.12

				--Begin Test case NegativeRequestCheck.4.13
				--Description: hashID: Escape sequence \n

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_hashIDNewLineChar()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_hashIDNewLineChar() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																		hashID = "hash\nID"
																	}) 
						 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)

					end

				--End Test case NegativeRequestCheck.4.13

				--Begin Test case NegativeRequestCheck.4.14
				--Description: hashID: Escape sequence \t

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_hashIDTabChar()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_hashIDTabChar() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																		hashID = "hash\tID"
																	}) 
						 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)

					end

				--End Test case NegativeRequestCheck.4.14

				--Begin Test case NegativeRequestCheck.4.15
				--Description: hashID: Only whitespace

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_hashIDWhitespace()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_hashIDWhitespace() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																		hashID = "        "
																	}) 
						 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)

					end

				--End Test case NegativeRequestCheck.4.15

				--Begin Test case NegativeRequestCheck.4.16
				--Description: hardware: Escape sequence \n

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_hardwareNewLineChar()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_hardwareNewLineChar() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																		deviceInfo = 
																		{
																			hardware = "hard\nware"
																		}
																	}) 
						 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)

					end

				--End Test case NegativeRequestCheck.4.16

				--Begin Test case NegativeRequestCheck.4.17
				--Description: hardware: Escape sequence \t

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_hardwareTabChar()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_hardwareTabChar() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																		deviceInfo = 
																		{
																			hardware = "hard\tware"
																		}
																	}) 
						 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)

					end

				--End Test case NegativeRequestCheck.4.17

				--Begin Test case NegativeRequestCheck.4.18
				--Description:hardware: Only whitespace

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_hardwareWhitespace()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_hardwareWhitespace() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																		deviceInfo = 
																		{
																			hardware = "        "
																		}
																	}) 
						 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)

					end

				--End Test case NegativeRequestCheck.4.18

				--Begin Test case NegativeRequestCheck.4.19
				--Description:firmwareRev: Escape sequence \n

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_firmwareRevNewLineChar()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_firmwareRevNewLineChar() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																		deviceInfo = 
																		{
																			firmwareRev = "firm\nwareRev"
																		}
																	}) 
						 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)

					end

				--End Test case NegativeRequestCheck.4.19

				--Begin Test case NegativeRequestCheck.4.20
				--Description: firmwareRev: Escape sequence \t

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_firmwareRevTabChar()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_firmwareRevTabChar() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																		deviceInfo = 
																		{
																			firmwareRev = "firm\twareRev"
																		}
																	}) 
						 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)

					end

				--End Test case NegativeRequestCheck.4.20

				--Begin Test case NegativeRequestCheck.4.21
				--Description: firmwareRev: Only whitespace

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_firmwareRevWhitespace()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_firmwareRevWhitespace() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																		deviceInfo = 
																		{
																			firmwareRev = "        "
																		}
																	}) 
						 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)

					end

				--End Test case NegativeRequestCheck.4.21

				--Begin Test case NegativeRequestCheck.4.22
				--Description: os: Escape sequence \n

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_osNewLineChar()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_osNewLineChar() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																		deviceInfo = 
																		{
																			os = "QN\nX"
																		}
																	}) 
						 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)

					end

				--End Test case NegativeRequestCheck.4.22

				--Begin Test case NegativeRequestCheck.4.23
				--Description: os: Escape sequence \t

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_osTabChar()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_osTabChar() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																		deviceInfo = 
																		{
																			os = "fQN\tX"
																		}
																	}) 
						 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)

					end

				--End Test case NegativeRequestCheck.4.23

				--Begin Test case NegativeRequestCheck.4.24
				--Description: os: Only whitespace

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_osWhitespace()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_osWhitespace() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																		deviceInfo = 
																		{
																			os = "        "
																		}
																	}) 
						 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)

					end

				--End Test case NegativeRequestCheck.4.24

				--Begin Test case NegativeRequestCheck.4.25
				--Description: osVersion: Escape sequence \n

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_osVersionNewLineChar()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_osVersionNewLineChar() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																		deviceInfo = 
																		{
																			osVersion = "QNX\nVersion"
																		}
																	}) 
						 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)

					end

				--End Test case NegativeRequestCheck.4.25

				--Begin Test case NegativeRequestCheck.4.26
				--Description: osVersion: Escape sequence \t

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_osTabChar()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_osTabChar()

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																		deviceInfo = 
																		{
																			osVersion = "fQN\tX"
																		}
																	}) 
						 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)

					end

				--End Test case NegativeRequestCheck.4.26

				--Begin Test case NegativeRequestCheck.4.27
				--Description: osVersion: Only whitespace

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_osVersionWhitespace()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_osVersionWhitespace() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																		deviceInfo = 
																		{
																			osVersion = "        "
																		}
																	}) 
						 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)

					end

				--End Test case NegativeRequestCheck.4.27

				--Begin Test case NegativeRequestCheck.4.28
				--Description: carrier: Escape sequence \n

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_carrierNewLineChar()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_carrierNewLineChar() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																		deviceInfo = 
																		{
																			carrier = "carr\nier"
																		}
																	}) 
						 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)

					end

				--End Test case NegativeRequestCheck.4.28

				--Begin Test case NegativeRequestCheck.4.29
				--Description: carrier: Escape sequence \t

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_carrierTabChar()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_carrierTabChar() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																		deviceInfo = 
																		{
																			carrier = "carr\tier"
																		}
																	}) 
						 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)

					end

				--End Test case NegativeRequestCheck.4.29

				--Begin Test case NegativeRequestCheck.4.30
				--Description: carrier: Only whitespace

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_carrierWhitespace()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_carrierWhitespace() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																		deviceInfo = 
																		{
																			carrier = "        "
																		}
																	}) 
						 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)

					end

				--End Test case NegativeRequestCheck.4.30

			--End Test case NegativeRequestCheck.4

			--Begin Test case NegativeRequestCheck.5
			--Description: Check processing requests with not existernt values()

				--Requirement id in JAMA: SDLAQ-CRS-1317, SDLAQ-CRS-1137

				--Verification criteria: - AppHMITypes different from DEFAULT, COMMUNICATION, MEDIA, MESSAGING, NAVIGATION, INFORMATION, SOCIAL, BACKGROUND_PROCESS, TESTING and SYSTEM are processed by RegisterAppInterface with INVALID_DATA in response resultCode.
				-- - SDL must respond with INVALID_DATA resultCode in case RegisterAppInterface request comes with parameters out of bounds (number or enum range)
				-- - The request with "languageDesired" parameter of enum range is sent, the response comes with «INVALID_DATA» result code.
				-- - The request with "hmiDisplayLanguageDesired" parameter of enum range is sent, the response comes with «INVALID_DATA» result code.


				--Begin Test case NegativeRequestCheck.5.1
				--Description: ttsName: type is not exist

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_ttsNameTypeNotExist()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_ttsNameTypeNotExist() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		ttsName = 
																		{ 
																			 
																			{ 
																				text ="wrongvalue",
																				type ="wrong_value",
																			}, 
																		}, 
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)
					end

				--End Test case NegativeRequestCheck.5.1

				--Begin Test case NegativeRequestCheck.5.2
				--Description: languageDesired: is not exist

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_langDesNotExist()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_langDesNotExist() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="AA-AA",
																		hmiDisplayLanguageDesired ="EN-US",
																		appID ="123456",
																	
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)

					end

				--End Test case NegativeRequestCheck.5.2

				--Begin Test case NegativeRequestCheck.5.3
				--Description: hmiDisplayLanguageDesired: is not exist

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_hmiDisplayLangNotExist()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_hmiDisplayLangNotExist() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="BB-BB",
																		appID ="123456",
																	
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)

					end

				--End Test case NegativeRequestCheck.5.3

				--Begin Test case NegativeRequestCheck.5.4
				--Description: appHMIType: is not exist

					--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_appHMITypeNotExist()
						OpenConnectionCreateSession(self)
					end

					function Test:RegisterAppInterface_appHMITypeNotExist() 

						--mobile side: RegisterAppInterface request 
						local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																	{
																	  	 
																		syncMsgVersion = 
																		{ 
																			majorVersion = 2,
																			minorVersion = 2,
																		}, 
																		appName ="SyncProxyTester",
																		isMediaApplication = AppMediaType,
																		languageDesired ="EN-US",
																		hmiDisplayLanguageDesired ="EN-US",
																		appHMIType = 
																		{ 
																			"ZZZZZZ",
																		}, 
																		appID ="123456",
																	
																	}) 
					 

						--mobile side: RegisterAppInterface response 
						EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "INVALID_DATA"})
							:Timeout(2000)

					end

				--End Test case NegativeRequestCheck.5.4

				
			--End Test case NegativeRequestCheck.5


		--End Test suit NegativeRequestCheck


	--=================================================================================--
	---------------------------------Negative response check-----------------------------
	--=================================================================================--

		-- Note: Response parameters will be tested in SetDisplayLayout script

----------------------------------------------------------------------------------------------
----------------------------------------IV TEST BLOCK-----------------------------------------
---------------------------------------Result codes check--------------------------------------
----------------------------------------------------------------------------------------------

		--------Checks-----------
		-- сheck all pairs resultCode+success
		-- check should be made sequentially (if it is possible):
		-- case resultCode + success true
		-- case resultCode + success false
			--For example:
				-- first case checks ABORTED + true
				-- second case checks ABORTED + false
			    -- third case checks REJECTED + true
				-- fourth case checks REJECTED + false

	--Begin Test suit ResultCodeCheck
	--Description:TC's check all resultCodes values in pair with success value

		--Begin Test case ResultCodeCheck.1
		--Description: Check of DUPLICATE_NAME response

			--Requirement id in JAMA: SDLAQ-CRS-362

			--Verification criteria:
				--[[ 
				- When SDL receives RegisterAppInterface RPC from mobile app, SDL must validate "appName" at first and validate the "appID" at second.

				- In case the app registers with the same "appName" and different "appID" as the already registered one, SDL must return "resultCode: DUPLICATE_NAME, success: false" to such app.

				- In case the app registers with the same "appName" and the same "appID" as the already registered one, SDL must return "resultCode: DUPLICATE_NAME, success: false" to such app.

				- In case the app registers with the same "appName" as one of already registered "vrSynonyms" of other apps, SDL must return "resultCode: DUPLICATE_NAME, success: false" to such app. (that is, appName should not coinside with any of VrSynonims of already registered apps)
				]]

				--Precondition:  open connection and create session
					function Test:EsteblishConnectionSession_UniqueSUCCESS()
						OpenConnectionCreateSession(self)
					end

				--Precondition: Register  app
				function Test:RegisterAppInterface_UniqueSUCCESS() 

	 				--mobile side: RegisterAppInterface request 
					local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																{
																  	 
																	syncMsgVersion = 
																	{ 
																		majorVersion = 2,
																		minorVersion = 2,
																	}, 
																	appName ="UniqueName",
																	ttsName = 
																	{ 
																		 
																		{ 
																			text ="UNA",
																			type ="TEXT",
																		}, 
																	}, 
																	vrSynonyms = 
																	{ 
																		"VRUnique",
																		"Start",
																	}, 
																	isMediaApplication = AppMediaType,
																	languageDesired ="EN-US",
																	hmiDisplayLanguageDesired ="EN-US",
																	appID ="11111",
																
																}) 
	
					--hmi side: expected  BasicCommunication.OnAppRegistered
					EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
								            {
								              	application = 
								              	{
								                	appName = "UniqueName",
													policyAppID = "11111",
													hmiDisplayLanguageDesired = "EN-US",
													isMediaApplication = AppMediaType
								              	}
								            })


					--mobile side: RegisterAppInterface response 
					EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
						:Timeout(2000)

					EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

				end

			--Begin Test case ResultCodeCheck.1.1
			--Description: RegisterAppInterface with appName = "UniqueName"

				--Precondition Openning new session
				function Test:Case_SecondSession_appNameDuplicateAppName()
				  -- Connected expectation
				  self.mobileSession1 = mobile_session.MobileSession(
				    self,
				    self.mobileConnection)
				  self.mobileSession1:StartService(7)
				end

				function Test:RegisterAppInterface_appNameDuplicateAppName() 

					--mobile side: RegisterAppInterface request 
					local CorIdRAI = self.mobileSession1:SendRPC("RegisterAppInterface",
																{
																  	 
																	syncMsgVersion = 
																	{ 
																		majorVersion = 2,
																		minorVersion = 2,
																	}, 
																	appName ="UniqueName",
																	ttsName = 
																	{ 
																		 
																		{ 
																			text ="SPT",
																			type ="TEXT",
																		}, 
																	}, 
																	vrSynonyms = 
																	{ 
																		"SyncProxyTester",
																	}, 
																	isMediaApplication = AppMediaType,
																	languageDesired ="EN-US",
																	hmiDisplayLanguageDesired ="EN-US",
																	appID ="123457",
																
																})


					--mobile side: RegisterAppInterface response 
					self.mobileSession1:ExpectResponse(CorIdRAI, { success = false, resultCode = "DUPLICATE_NAME"})
						:Timeout(2000)

				end

			--End Test case ResultCodeCheck.1.1

			-- Begin Test case ResultCodeCheck.1.2
			-- Description: RegisterAppInterface with appName = vrSynonym "VRUnique"
				-- Precondition:  open connection and create session
				function Test:EsteblishConnectionSession_appNameDuplicateVRSynonym()
					OpenConnectionCreateSession(self)
				end

				--Precondition Openning new session
				function Test:Case_SecondSession_appNameDuplicateVRSynonym()
				  -- Connected expectation
				  self.mobileSession1 = mobile_session.MobileSession(
				    self,
				    self.mobileConnection)
				  self.mobileSession1:StartService(7)
				end

				function Test:RegisterAppInterface_appNameDuplicateVRSynonym() 

	 				--mobile side: RegisterAppInterface request 
					local CorIdRAI = self.mobileSession1:SendRPC("RegisterAppInterface",
																{
																  	 
																	syncMsgVersion = 
																	{ 
																		majorVersion = 2,
																		minorVersion = 2,
																	}, 
																	appName ="VRUnique",
																	ttsName = 
																	{ 
																		 
																		{ 
																			text ="SPT",
																			type ="TEXT",
																		}, 
																	}, 
																	vrSynonyms = 
																	{ 
																		"SyncProxyTester",
																	}, 
																	isMediaApplication = AppMediaType,
																	languageDesired ="EN-US",
																	hmiDisplayLanguageDesired ="EN-US",
																	appID ="123458",
																
																})

					--mobile side: RegisterAppInterface response 
					self.mobileSession1:ExpectResponse(CorIdRAI, { success = false, resultCode = "DUPLICATE_NAME"})
						:Timeout(2000)


				end

			--End Test case ResultCodeCheck.1.2

			--Begin Test case ResultCodeCheck.1.3
			--Description: RegisterAppInterface with vrSynonym = appName "UniqueName"

				--Precondition:  open connection and create session
				function Test:EsteblishConnectionSession_VRSynDuplicateAppName()
					OpenConnectionCreateSession(self)
				end

				--Precondition Openning new session
				function Test:Case_SecondSession_VRSynDuplicateAppName()
				  -- Connected expectation
				  self.mobileSession1 = mobile_session.MobileSession(
				    self,
				    self.mobileConnection)
				  self.mobileSession1:StartService(7)
				end

				function Test:RegisterAppInterface_VRSynDuplicateAppName() 

					--mobile side: RegisterAppInterface request 
					local CorIdRAI = self.mobileSession1:SendRPC("RegisterAppInterface",
																{
																  	 
																	syncMsgVersion = 
																	{ 
																		majorVersion = 2,
																		minorVersion = 2,
																	}, 
																	appName ="SyncProxy",
																	ttsName = 
																	{ 
																		 
																		{ 
																			text ="SyncProxy",
																			type ="TEXT",
																		}, 
																	}, 
																	vrSynonyms = 
																	{ 
																		"UniqueName",
																	}, 
																	isMediaApplication = AppMediaType,
																	languageDesired ="EN-US",
																	hmiDisplayLanguageDesired ="EN-US",
																	appID ="123461",
																
																})

					--mobile side: RegisterAppInterface response 
					self.mobileSession1:ExpectResponse(CorIdRAI, { success = false, resultCode = "DUPLICATE_NAME"})
						:Timeout(2000)

				end

			--End Test case ResultCodeCheck.1.3

			--Begin Test case ResultCodeCheck.1.4
			--Description: RegisterAppInterface with appID = appID "123456" and appName = appName "UniqueName"

				--Precondition:  open connection and create session
				function Test:EsteblishConnectionSession_appIDappNameDuplicateAppIDappName()
					OpenConnectionCreateSession(self)
				end

				--Precondition Openning new session
				function Test:Case_SecondSession_appIDappNameDuplicateAppIDappName()
				  -- Connected expectation
				  self.mobileSession1 = mobile_session.MobileSession(
				    self,
				    self.mobileConnection)
				  self.mobileSession1:StartService(7)
				end

				function Test:RegisterAppInterface_appIDappNameDuplicateAppIDappName() 

					--mobile side: RegisterAppInterface request 
					local CorIdRAI = self.mobileSession1:SendRPC("RegisterAppInterface",
																{
																  	 
																	syncMsgVersion = 
																	{ 
																		majorVersion = 2,
																		minorVersion = 2,
																	}, 
																	appName ="UniqueName",
																	ttsName = 
																	{ 
																		 
																		{ 
																			text ="Testes",
																			type ="TEXT",
																		}, 
																	}, 
																	vrSynonyms = 
																	{ 
																		"Testes",
																	}, 
																	isMediaApplication = AppMediaType,
																	languageDesired ="EN-US",
																	hmiDisplayLanguageDesired ="EN-US",
																	appID ="11111",
																
																})

					--mobile side: RegisterAppInterface response 
					self.mobileSession1:ExpectResponse(CorIdRAI, { success = false, resultCode = "DUPLICATE_NAME"})
						:Timeout(2000)

				end

			--End Test case ResultCodeCheck.1.4

			
		--End Test case ResultCodeCheck.1


		--Begin Test case ResultCodeCheck.2
		--Description: Check of WARNINGS response

			--Requirement id in JAMA: SDLAQ-CRS-1047, SDLAQ-CRS-1137

			--Verification criteria:
				--The request result is success but the result code is WARNING when ttsName is recieved as a SAPI_PHONEMES or LHPLUS_PHONEMES or PRE_RECORDED or SILENCE. ttsName has not been sent to TTS component for futher processing, the other parts of the request are sent to HMI. The response's "Info" parameter provides the information that not supported TTSChunk type is used. 
				--Any TTSChunk sent from mobile app contains text to be spoken and a type of TTSChunk. SDL re-sends the valid RPC to HMI.

			--Begin Test case ResultCodeCheck.2.1
			--Description: ttsName: type = PRE_RECORDED

			-- Precondition:  open connection and create session
			function Test:EsteblishConnectionSession_ttsNameTypePrerec()
				OpenConnectionCreateSession(self)
			end

			function Test:RegisterAppInterface_ttsNameTypePrerec() 

				--mobile side: RegisterAppInterface request 
				local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
															{
															  	 
																syncMsgVersion = 
																{ 
																	majorVersion = 2,
																	minorVersion = 2,
																}, 
																appName ="SyncProxyTester",
																ttsName = 
																{ 
																	 
																	{ 
																		text ="4005",
																		type ="PRE_RECORDED",
																	}, 
																}, 
																isMediaApplication = AppMediaType,
																languageDesired ="EN-US",
																hmiDisplayLanguageDesired ="EN-US",
																appID ="123456",
															
															})

				--mobile side: RegisterAppInterface response 
				self.mobileSession:ExpectResponse(CorIdRAI, { success = true, resultCode = "WARNINGS"})

			end	

			--End Test case ResultCodeCheck.2.1

			--Begin Test case ResultCodeCheck.2.2
			--Description: ttsName: type = SAPI_PHONEMES

			-- Precondition: The application should be unregistered before next test.
			function Test:UnregisterAppInterface_Success_ttsNameTypeSAPI() 
				UnregisterApplicationSessionOne(self) 
			end

			function Test:RegisterAppInterface_ttsNameTypeSAPI() 

				--mobile side: RegisterAppInterface request 
				local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
															{
															  	 
																syncMsgVersion = 
																{ 
																	majorVersion = 2,
																	minorVersion = 2,
																}, 
																appName ="SyncProxyTester",
																ttsName = 
																{ 
																	 
																	{ 
																		text ="4005",
																		type ="SAPI_PHONEMES",
																	}, 
																}, 
																isMediaApplication = AppMediaType,
																languageDesired ="EN-US",
																hmiDisplayLanguageDesired ="EN-US",
																appID ="123456",
															
															})

				--mobile side: RegisterAppInterface response 
				self.mobileSession:ExpectResponse(CorIdRAI, { success = true, resultCode = "WARNINGS"})

			end	

			--End Test case ResultCodeCheck.2.2

			--Begin Test case ResultCodeCheck.2.3
			--Description: ttsName: type = LHPLUS_PHONEMES

			-- Precondition: The application should be unregistered before next test.
			function Test:UnregisterAppInterface_Success_ttsNameTypeLHPLUS() 
				UnregisterApplicationSessionOne(self) 
			end

			function Test:RegisterAppInterface_ttsNameTypeLHPLUS() 

				--mobile side: RegisterAppInterface request 
				local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
															{
															  	 
																syncMsgVersion = 
																{ 
																	majorVersion = 2,
																	minorVersion = 2,
																}, 
																appName ="SyncProxyTester",
																ttsName = 
																{ 
																	 
																	{ 
																		text ="4005",
																		type ="LHPLUS_PHONEMES",
																	}, 
																}, 
																isMediaApplication = AppMediaType,
																languageDesired ="EN-US",
																hmiDisplayLanguageDesired ="EN-US",
																appID ="123456",
															
															})

				--mobile side: RegisterAppInterface response 
				self.mobileSession:ExpectResponse(CorIdRAI, { success = true, resultCode = "WARNINGS"})

			end	

			--End Test case ResultCodeCheck.2.3

			--Begin Test case ResultCodeCheck.2.4
			--Description: ttsName: type = SILENCE

			-- Precondition: The application should be unregistered before next test.
			function Test:UnregisterAppInterface_Success_ttsNameTypeSilence() 
				UnregisterApplicationSessionOne(self) 
			end

			function Test:RegisterAppInterface_ttsNameTypeSilence() 

				--mobile side: RegisterAppInterface request 
				local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
															{
															  	 
																syncMsgVersion = 
																{ 
																	majorVersion = 2,
																	minorVersion = 2,
																}, 
																appName ="SyncProxyTester",
																ttsName = 
																{ 
																	 
																	{ 
																		text ="4005",
																		type ="SILENCE",
																	}, 
																}, 
																isMediaApplication = AppMediaType,
																languageDesired ="EN-US",
																hmiDisplayLanguageDesired ="EN-US",
																appID ="123456",
															
															})

				--mobile side: RegisterAppInterface response 
				self.mobileSession:ExpectResponse(CorIdRAI, { success = true, resultCode = "WARNINGS"})

			end	

			--End Test case ResultCodeCheck.2.4

		--End Test case ResultCodeCheck.2

		--Begin Test case ResultCodeCheck.3
		--Description: Check of APPLICATION_REGISTERED_ALREADY response

			--Requirement id in JAMA: SDLAQ-CRS-364

			--Verification criteria: SDL sends APPLICATION_REGISTERED_ALREADY code when the app sends RegisterAppInterface within the same connection after RegisterAppInterface has been already sent and not unregistered yet.


				-- Precondition: The application should be unregistered before next test.
				function Test:UnregisterAppInterface_Success_ApplicationRegisteredAlready() 
					UnregisterApplicationSessionOne(self) 
				end


				function Test:RegisterAppInterface_ApplicationRegisteredAlready()

					--mobile side: RegisterAppInterface request 
					self.mobileSession:SendRPC("RegisterAppInterface",
															{
															  	 
																syncMsgVersion = 
																{ 
																	majorVersion = 2,
																	minorVersion = 2,
																}, 
																appName ="ProxyTester1",
																isMediaApplication = AppMediaType,
																languageDesired ="EN-US",
																hmiDisplayLanguageDesired ="EN-US",
																appID ="12345",
															
															})

				 
					--mobile side: RegisterAppInterface response 
					EXPECT_RESPONSE("RegisterAppInterface", 
						{ success = true, resultCode = "SUCCESS"},
						{ success = false, resultCode = "APPLICATION_REGISTERED_ALREADY"})
						:Times(2)
						:Do(function(exp,data)

							if exp.occurences == 1 then

								self.mobileSession:SendRPC("RegisterAppInterface",
															{
															  	 
																syncMsgVersion = 
																{ 
																	majorVersion = 2,
																	minorVersion = 2,
																}, 
																appName ="ProxyTester2",
																isMediaApplication = AppMediaType,
																languageDesired ="EN-US",
																hmiDisplayLanguageDesired ="EN-US",
																appID ="12345",
															
															})
							end

						end)

					EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

				end

		--End Test case ResultCodeCheck.3

		--Begin Test case ResultCodeCheck.4
		--Description: Check of WRONG_LANGUAGE response

			--Requirement id in JAMA: SDLAQ-CRS-366

			--Verification criteria:
			--[[
			 - SDL sends the WRONG_LANGUAGE response result code when the app is registering with languageDesired different from the current one on VR+TTS. The app's VR+TTS language is the same as current on VR/TTS on HMI. General request result is success=true.
			- SDL sends the response WRONG_LANGUAGE when app is registering with hmiDisplayLanguageDesired different from the current one on HMI. The app's UI language is the same as current on UI on HMI.General request result is success=true.
			]]

			--Begin Test case ResultCodeCheck.4.1
			--Description: languageDesired different from the current one on VR+TTS

				-- Precondition:  open connection and create session
				function Test:EsteblishConnectionSession_languageDesiredWrongLanguage()
					OpenConnectionCreateSession(self)
				end

				function Test:RegisterAppInterface_languageDesiredWrongLanguage()

					--mobile side: RegisterAppInterface request 
					local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
															{
																syncMsgVersion = 
																{ 
																	majorVersion = 2,
																	minorVersion = 2,
																}, 
																appName ="SyncProxyTester",
																isMediaApplication = AppMediaType,
																languageDesired = "DE-DE",
																hmiDisplayLanguageDesired ="EN-US",
																appID ="123456",
															}) 
	 
			 		--hmi side: expected  BasicCommunication.OnAppRegistered
					EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
								            {
								              	application = 
								              	{
								                	appName = "SyncProxyTester",
													policyAppID = "123456",
													hmiDisplayLanguageDesired ="EN-US",
													isMediaApplication = AppMediaType
								              	}
								            })


					--mobile side: RegisterAppInterface response 
					EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "WRONG_LANGUAGE"})
						:Timeout(2000)

				end

			--End Test case ResultCodeCheck.4.1

			--Begin Test case ResultCodeCheck.4.1
			--Description:   hmiDisplayLanguageDesired different from the current one on HMI

				-- Precondition: The application should be unregistered before next test.
				function Test:UnregisterAppInterface_Success_languageDesiredWrongLanguage() 
					UnregisterApplicationSessionOne(self) 
				end

				function Test:RegisterAppInterface_languageDesiredWrongLanguage()

					--mobile side: RegisterAppInterface request 
					local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
															{
																syncMsgVersion = 
																{ 
																	majorVersion = 2,
																	minorVersion = 2,
																}, 
																appName ="SyncProxyTester",
																isMediaApplication = AppMediaType,
																languageDesired = "EN-US",
																hmiDisplayLanguageDesired ="DE-DE",
																appID ="123456",
															}) 
	 
			 		--hmi side: expected  BasicCommunication.OnAppRegistered
					EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
								            {
								              	application = 
								              	{
								                	appName = "SyncProxyTester",
													policyAppID = "123456",
													hmiDisplayLanguageDesired ="DE-DE",
													isMediaApplication = AppMediaType
								              	}
								            })


					--mobile side: RegisterAppInterface response 
					EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "WRONG_LANGUAGE"})
						:Timeout(2000)

				end

			--End Test case ResultCodeCheck.4.1

		--End Test case ResultCodeCheck.4

		--Begin Test case ResultCodeCheck.5
		--Description: Check of DISALLOWED response

			--Requirement id in JAMA: SDLAQ-CRS-368

			--Verification criteria: 
			--[[- PoliciesManager must disallow the app`s registration IN CASE the app`s nickname does not match those listed 	in Policy Table under the appID this app registers with (see SDLAQ-CRS-2385).

				- PoliciesManager must disallow the app`s registration IN CASE the appID this app registers with has "null" permissions in Policy Table (SDLAQ-CRS-2388)

				- In case the app registers with the same "appID" and different "appName" as the already registered one, SDL must return "resultCode: DISALLOWED, success: false" to such app.]]

			--Begin Test case ResultCodeCheck.5.1
			--Description: App`s nickname does not match those listed in Policy Table under the appID this app registers with

				-- Precondition: The application should be unregistered before next test.
				function Test:UnregisterAppInterface_Success_appNameDoesNotMatchToPTDisallowed() 
					UnregisterApplicationSessionOne(self) 
				end

				function Test:RegisterAppInterface_appNameDoesNotMatchToPTDisallowed()

					--mobile side: RegisterAppInterface request 
					local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
															{
															  	 
																syncMsgVersion = 
																{ 
																	majorVersion = 2,
																	minorVersion = 2,
																}, 
																appName ="SyncProxyTester",
																isMediaApplication = AppMediaType,
																languageDesired ="EN-US",
																hmiDisplayLanguageDesired ="EN-US",
																appID ="654321",
															
															})

				 
					--mobile side: RegisterAppInterface response 
					EXPECT_RESPONSE(CorIdRAI, { success = false, resultCode = "DISALLOWED"})

				end

			--End Test case ResultCodeCheck.5.1

			--Begin Test case ResultCodeCheck.5.2
			--Description:appID this app registers with has "null" permissions in Policy Table

				-- Precondition:  open connection and create session
				function Test:EsteblishConnectionSession_appIDnullPermissionsDisallowed()
					OpenConnectionCreateSession(self)
				end

				function Test:RegisterAppInterface_appIDnullPermissionsDisallowed()

					--mobile side: RegisterAppInterface request 
					local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
															{
															  	 
																syncMsgVersion = 
																{ 
																	majorVersion = 2,
																	minorVersion = 2,
																}, 
																appName ="SyncProxyTester",
																isMediaApplication = AppMediaType,
																languageDesired ="EN-US",
																hmiDisplayLanguageDesired ="EN-US",
																appID ="33333",
															
															})

				 
					--mobile side: RegisterAppInterface response s
					EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
						:Do(function(_,data)
							local CorIdUAI = self.mobileSession:SendRPC("UnregisterAppInterface",{}) 

							 --mobile side: UnregisterAppInterface response 
							self.mobileSession:ExpectResponse(CorIdUAI, { success = false, resultCode = "DISALLOWED"})
								:Timeout(2000)
								:Do(function(_,data)
									-- self.mobileConnection:Close()
									self.mobileConnection:Close()
								end)

						end)


				end

			-- --End Test case ResultCodeCheck.5.2


			--Begin Test case ResultCodeCheck.5.3
			--Description: app registers with the same "appID" and different "appName" as the already registered one

				-- Precondition:  open connection and create session
				function Test:EsteblishConnectionSession_appIDDuplicateDisallowed()
					OpenConnectionCreateSession(self)
				end

				--Precondition Opening new session
				function Test:Case_SecondSession_appIDDuplicateDisallowed()
				  -- Connected expectation
				  self.mobileSession1 = mobile_session.MobileSession(
				    self,
				    self.mobileConnection)
				  self.mobileSession1:StartService(7)
				end

				function Test:RegisterAppInterface_appIDDuplicateDisallowed()

					--mobile side: RegisterAppInterface request 
					local CorIdRAI1 = self.mobileSession:SendRPC("RegisterAppInterface",
															{
															  	 
																syncMsgVersion = 
																{ 
																	majorVersion = 2,
																	minorVersion = 2,
																}, 
																appName ="SyncTester",
																isMediaApplication = AppMediaType,
																languageDesired ="EN-US",
																hmiDisplayLanguageDesired ="EN-US",
																appID ="2233",
															
															})

				 
					--mobile side: RegisterAppInterface response 
					EXPECT_RESPONSE(CorIdRAI1, { success = true, resultCode = "SUCCESS"})
						:Do(function(exp,data)

							if exp.occurences == 1 then

								local CorIdRAI2 = self.mobileSession1:SendRPC("RegisterAppInterface",
															{
															  	 
																syncMsgVersion = 
																{ 
																	majorVersion = 2,
																	minorVersion = 2,
																}, 
																appName ="SyncProxyTester",
																isMediaApplication = AppMediaType,
																languageDesired ="EN-US",
																hmiDisplayLanguageDesired ="EN-US",
																appID ="2233",
															
															})

								--mobile side: RegisterAppInterface response 
								self.mobileSession1:ExpectResponse(CorIdRAI2, { success = false, resultCode = "DISALLOWED"})

							end

						end)

					EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

				end
			--End Test case ResultCodeCheck.5.3

		--End Test case ResultCodeCheck.5

		--Begin Test case ResultCodeCheck.6
		--Description: Check of RESUME_FAILED response

			--Requirement id in JAMA: SDLAQ-CRS-2754

			--Verification criteria: 
				--The provided hash ID does not match the hash of the current set of registered data or the core could not resume the previous data.
				--SDL returns RegisterAppInterface response of (success: true, resultCode: RESUME_FAILED) IN CASE SDL has faild to restore mobile application`s persistent data.

				-- Precondition:  open connection and create session
				function Test:EsteblishConnectionSession_ResumeFailed()
					OpenConnectionCreateSession(self)
				end

				function Test:RegisterAppInterface_ResumeFailed() 
					--mobile side: RegisterAppInterface request 
					local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
																{
																  	 
																	syncMsgVersion = 
																	{ 
																		majorVersion = 2,
																		minorVersion = 2,
																	}, 
																	appName ="SPTResumeFailed",
																	isMediaApplication = AppMediaType,
																	languageDesired ="EN-US",
																	hmiDisplayLanguageDesired ="EN-US",
																	appID ="123456",
																	hashID = "somehashIDValue"
																})

					--hmi side: expected  BasicCommunication.OnAppRegistered
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
						            {
						              	application = 
						              	{
						                	appName = "SPTResumeFailed",
											policyAppID = "123456",
											hmiDisplayLanguageDesired ="EN-US",
											isMediaApplication = AppMediaType
						              	}
						            })

					--mobile side: RegisterAppInterface response 
					EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "RESUME_FAILED"})
						:Timeout(2000)

			end

			function Test:UnregisterAppInterface_Success_ResumeFailed() 
				--mobile side: UnregisterAppInterface request 
				local CorIdUAI = self.mobileSession:SendRPC("UnregisterAppInterface",{}) 

				--hmi side: expect OnAppUnregistered notification 
					EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.applications["SPTResumeFailed"], unexpectedDisconnect = false})
			 

				 --mobile side: UnregisterAppInterface response 
				EXPECT_RESPONSE(CorIdUAI, { success = true, resultCode = "SUCCESS"})
			end

		--End Test case ResultCodeCheck.6


		--TODO OUT_OF_MEMORY SDLAQ-CRS-360 -  APPLINK-13411


	--End Test suit ResultCodeCheck

----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VI----------------------------------------
-------------------------Sequence with emulating of user's action(s)--------------------------
----------------------------------------------------------------------------------------------


-- 01[P][MAN]_TC_SDL_converts_hex_values_from_.ini
--===================================================================================--
-- SDL converts the hex values taken from smartdeviceLink.ini file to integer ones and sends the converted values within supportedDiagModes parameter in response to RegisterAppInterface.
--===================================================================================--


----------------------------------------------------------------------------
-- Common values in supportedDiagModes
-- supportedDiagModes:  minvalue="0", maxvalue="255", minsize="1", maxsize="100"

--Precondition: Valid value in .ini file "0x01, 0x02, 0x03, 0x05, 0x06, 0x07, 0x09, 0x0A, 0x18, 0x19, 0x22, 0x3E"
RestartSDLChangingSupportedDiagModesValue(self, "SupportedDiagModes_ValidValue", "0x01, 0x02, 0x03, 0x05, 0x06, 0x07, 0x09, 0x0A, 0x18, 0x19, 0x22, 0x3E")

function Test:ValidValueOfsupportedDiagModesInIniFile()
	userPrint(34, "=================================== Test  Case ===================================")

	AppRegistration(self, RAIParams, {1,2,3,5,6,7,9,10,24,25,34,62})
end

----------------------------------------------------------------------------
-- lower bound value, lower bound size in supportedDiagModes

--Precondition: Lower bound value in .ini file 0x00
RestartSDLChangingSupportedDiagModesValue(self, "SupportedDiagModes_LowerBoundValue", "0x00")

function Test:LowerBoundValueOfsupportedDiagModesInIniFile()
	userPrint(34, "=================================== Test  Case ===================================")

	AppRegistration(self, RAIParams, {0})
end

----------------------------------------------------------------------------
-- upper bound value,  lower bound size in supportedDiagModes

--Precondition: Lower bound value in .ini file 0xFF
RestartSDLChangingSupportedDiagModesValue(self, "SupportedDiagModes_UpperBoundValue", "0xFF")

function Test:UpperBoundValueOfsupportedDiagModesInIniFile()
	userPrint(34, "=================================== Test  Case ===================================")

	AppRegistration(self, RAIParams, {255})
end

----------------------------------------------------------------------------
-- wrong type value in supportedDiagModes

--Precondition: wrong type in .ini file
RestartSDLChangingSupportedDiagModesValue(self, "SupportedDiagModes_WrongTypeValue", "string, 1")

function Test:WrongTypeOfsupportedDiagModesInIniFile()
	userPrint(34, "=================================== Test  Case ===================================")

	AppRegistration(self, RAIParams, {1})
end

----------------------------------------------------------------------------
-- missed array element in supportedDiagModes

--Precondition: wrong type in .ini file
RestartSDLChangingSupportedDiagModesValue(self, "SupportedDiagModes_MissedArrayElement", "1,,3")

function Test:MissedArrayElementOfsupportedDiagModesInIniFile()
	userPrint(34, "=================================== Test  Case ===================================")

	AppRegistration(self, RAIParams, {1,3})
end

----------------------------------------------------------------------------
-- out lower bound value in supportedDiagModes

--Precondition: negative value in .ini file "FFFFFFFFFFFFFFFF"
RestartSDLChangingSupportedDiagModesValue(self, "SupportedDiagModes_NegativeOutLowerBoundValue", "FFFFFFFFFFFFFFFF")

function Test:NegativeOutLowerBoundValueOfsupportedDiagModesInIniFile()
	userPrint(34, "=================================== Test  Case ===================================")

	AppRegistration(self, RAIParams, _)
end

----------------------------------------------------------------------------
-- out upper bound value in supportedDiagModes

--Precondition: out upper bound value in .ini file "0x100"
RestartSDLChangingSupportedDiagModesValue(self, "SupportedDiagModes_OutUpperBoundValue", "0x100")

function Test:OutUpperBoundValueOfsupportedDiagModesInIniFile()
	userPrint(34, "=================================== Test  Case ===================================")

	AppRegistration(self, RAIParams, _)
end

----------------------------------------------------------------------------
-- out lower bound size in supportedDiagModes

--Precondition: empty value in .ini file _
RestartSDLChangingSupportedDiagModesValue(self, "SupportedDiagModes_EmptyValue", "")

function Test:EmptyValueOfsupportedDiagModesInIniFile()
	userPrint(34, "=================================== Test  Case ===================================")

	AppRegistration(self, RAIParams, _)
end

----------------------------------------------------------------------------
-- upper bound size in supportedDiagModes
--TODO: after resolving issue with lower bound value, add 0 to hexArray, decArray arrays
local hexArray = "1,2,3,4,5,6,7,8,9,a,b,c,d,e,f,10,11,12,13,14,15,16,17,18,19,1a,1b,1c,1d,1e,1f,20,21,22,23,24,25,26,27,28,29,2a,2b,2c,2d,c9,ca,cb,cc,cd,ce,cf,d0,d1,d2,d3,d4,d5,d6,d7,d8,d9,da,db,dc,dd,de,df,e0,e1,e2,e3,e4,e5,e6,e7,e8,e9,ea,eb,ec,ed,ee,ef,f0,f1,f2,f3,f4,f5,f6,f7,f8,f9,fa,fb,fc,fd,fe,ff"
local decArray = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44,45, 201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218, 219, 220, 221, 222, 223, 224, 225, 226, 227, 228, 229, 230, 231, 232, 233, 234, 235, 236, 237, 238, 239, 240, 241, 242, 243, 244, 245, 246, 247, 248, 249, 250, 251, 252, 253, 254, 255}
--Precondition: upper bound size in .ini file _
RestartSDLChangingSupportedDiagModesValue(self, "SupportedDiagModes_UpperBoundSize", hexArray)

function Test:UpperBoundSizeOfsupportedDiagModesInIniFile()
	userPrint(34, "=================================== Test  Case ===================================")

	AppRegistration(self, RAIParams, decArray)
end

----------------------------------------------------------------------------
-- out upper bound size in supportedDiagModes

local hexArrayOutUpperBound = hexArray .. ", 1"

--Precondition: out upper bound size in .ini file _
RestartSDLChangingSupportedDiagModesValue(self, "SupportedDiagModes_OutUpperBoundSize", hexArrayOutUpperBound)

function Test:OutUpperBoundSizeOfsupportedDiagModesInIniFile()
	userPrint(34, "=================================== Test  Case ===================================")

	AppRegistration(self, RAIParams, _)
end

-- 02[P][MAN]_TC_SDL_adds_SW_version_to_RAI_response
--===================================================================================--
-- Check that SDL adds system SW version in RegisterAppInterface response.
--===================================================================================--
----------------------------------------------------------------------------
-- common systemSoftwareVersion value in RAI response
local GetSystemInfoValue = {
        ccpu_version = "user_ccpu_version",
        language = "EN-US",
        wersCountryCode = "user_wersCountryCode"
      }

RestartSDLChangingSupportedDiagModesValue(self, "GetSystemInfo",_, GetSystemInfoValue)

function Test:SDLsendsSystemSoftwareVersioninRAIresponse()
	userPrint(34, "=================================== Test  Case ===================================")

	local RAIResponseParam = {
		success = true,
		resultCode = "SUCCESS",
		systemSoftwareVersion = "user_ccpu_version"
	}

	RegisterApp(self, RAIParams, RAIResponseParam)
end

----------------------------------------------------------------------------
-- lower bound systemSoftwareVersion value in RAI response
local GetSystemInfoValue = {
        ccpu_version = "u",
        language = "EN-US",
        wersCountryCode = "user_wersCountryCode"
      }

RestartSDLChangingSupportedDiagModesValue(self, "lowerBound_ccpu_version",_, GetSystemInfoValue)

function Test:LowerBoundValueSystemSoftwareVersioninRAIresponse()
	userPrint(34, "=================================== Test  Case ===================================")

	local RAIResponseParam = {
		success = true,
		resultCode = "SUCCESS",
		systemSoftwareVersion = "u"
	}

	RegisterApp(self, RAIParams, RAIResponseParam)
end

----------------------------------------------------------------------------
-- upper bound systemSoftwareVersion value in RAI response
local GetSystemInfoValue = {
        ccpu_version = "1234567890!@#$%^&*()_+{}:|;',./<>?qwertyuiopASDFGHJKLzxcvbnm1234567890!@#$%^&*()_+{}:|;',./<>?qwerty",
        language = "EN-US",
        wersCountryCode = "user_wersCountryCode"
      }

RestartSDLChangingSupportedDiagModesValue(self, "upperBound_ccpu_version",_, GetSystemInfoValue)

function Test:UpperBoundValueSystemSoftwareVersioninRAIresponse()
	userPrint(34, "=================================== Test  Case ===================================")

	local RAIResponseParam = {
		success = true,
		resultCode = "SUCCESS",
		systemSoftwareVersion = "1234567890!@#$%^&*()_+{}:|;',./<>?qwertyuiopASDFGHJKLzxcvbnm1234567890!@#$%^&*()_+{}:|;',./<>?qwerty"
	}

	RegisterApp(self, RAIParams, RAIResponseParam)
end

-- 03[P][MAN]_TC_SDL_requests_systemSoftwareVersion_once
--===================================================================================--
-- Check that SDL request systemSoftwareVersion only once and use this value during ignition cycle.
--===================================================================================--
local GetSystemInfoValue = {
        ccpu_version = "FORD",
        language = "EN-US",
        wersCountryCode = "user_wersCountryCode"
      }

RestartSDLChangingSupportedDiagModesValue(self, "Set_GetSystemInfo",_, GetSystemInfoValue)

function Test:SDLsendsSystemSoftwareVersioninRAIresponseDuringFirstRegistration()
	userPrint(34, "=================================== Test  Case ===================================")

	local RAIResponseParam = {
		success = true,
		resultCode = "SUCCESS",
		systemSoftwareVersion = "FORD"
	}

	EXPECT_HMICALL("BasicCommunication.GetSystemInfo")
		:Times(0)

	RegisterApp(self, RAIParams, RAIResponseParam)
end

function Test:Precondition_UnregisterApp()
	--mobile side: UnregisterAppInterface request 
	local CorIdUAI = self.mobileSession:SendRPC("UnregisterAppInterface",{}) 

	--hmi side: expect OnAppUnregistered notification 
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.applications[config.application1.registerAppInterfaceParams.appName], unexpectedDisconnect = false})
 

	 --mobile side: UnregisterAppInterface response 
	EXPECT_RESPONSE(CorIdUAI, { success = true, resultCode = "SUCCESS"})
end

function Test:SDLsendsSystemSoftwareVersioninRAIresponseDuringSecondRegistration()
	userPrint(34, "=================================== Test  Case ===================================")
	userPrint(33, "Check that SDL log contain only one request BasicComminication.GetSystemInfo from SDL and one response from HMI during ignition cycle") 
	local RAIResponseParam = {
		success = true,
		resultCode = "SUCCESS",
		systemSoftwareVersion = "FORD"
	}

	EXPECT_HMICALL("BasicCommunication.GetSystemInfo")
		:Times(0)

	RegisterApp(self, RAIParams, RAIResponseParam)
end

local GetSystemInfoValue = {
        ccpu_version = "FORD_second_ignition_cycle",
        language = "EN-US",
        wersCountryCode = "user_wersCountryCode"
      }

RestartSDLChangingSupportedDiagModesValue(self, "GetSystemInfo_InSeconfIgnitionCycle","0x01, 0x02, 0x03, 0x05, 0x06, 0x07, 0x09, 0x0A, 0x18, 0x19, 0x22, 0x3E", GetSystemInfoValue)

-- 04[P][MAN]_TC_SDL_returns_version_in_RAI_response
--===================================================================================--
-- Check that SDL returns SDL version in RegisterAppInterface response
--===================================================================================--
----------------------------------------------------------------------------
-- sending sdlVersion in RAI response 
RestartSDLChangingSupportedDiagModesValue(self, "sdlVersion",_, _, "SDL_4")

function Test:SDLVersionInRAIResponse()
	userPrint(34, "=================================== Test  Case ===================================")

	local RAIResponseParam = {
		success = true,
		resultCode = "SUCCESS",
		sdlVersion = "SDL_4"
	}

	RegisterApp(self, RAIParams, RAIResponseParam)
end

----------------------------------------------------------------------------
-- sending lower bound value of sdlVersion in RAI response 
RestartSDLChangingSupportedDiagModesValue(self, "LowerBoundSdlVersionValue",_, _, "v")

function Test:LowerBoundSdlVersionValueInRAIResponse()
	userPrint(34, "=================================== Test  Case ===================================")

	local RAIResponseParam = {
		success = true,
		resultCode = "SUCCESS",
		sdlVersion = "v"
	}

	RegisterApp(self, RAIParams, RAIResponseParam)
end

----------------------------------------------------------------------------
-- sending empty sdlVersion value in RAI response in case out lower bound value in .ini file 
RestartSDLChangingSupportedDiagModesValue(self, "OutLowerBoundSdlVersionValue",_, _, "")

function Test:OutLowerBoundSdlVersionValueInRAIResponse()
	userPrint(34, "=================================== Test  Case ===================================")

	local RAIResponseParam = {
		success = true,
		resultCode = "SUCCESS",
		sdlVersion = ""
	}

	RegisterApp(self, RAIParams, RAIResponseParam)
end

----------------------------------------------------------------------------
-- sending upper bound value of sdlVersion in RAI response
RestartSDLChangingSupportedDiagModesValue(self, "UpperBoundSdlVersionValue",_, _, "1234567890!@#$%%^&*()_+{}:|<>?[];'\\,./qwertyuiopASDFGHJKLzxcvbnm1234567890!@#$%%^&*()_+{}:|<>?[];'\\,./")

function Test:UpperBoundSdlVersionValueInRAIResponse()
	userPrint(34, "=================================== Test  Case ===================================")

	local RAIResponseParam = {
		success = true,
		resultCode = "SUCCESS",
		sdlVersion = "1234567890!@#$%^&*()_+{}:|<>?[];'\\,./qwertyuiopASDFGHJKLzxcvbnm1234567890!@#$%^&*()_+{}:|<>?[];'\\,./"
	}

	RegisterApp(self, RAIParams, RAIResponseParam)
end

----------------------------------------------------------------------------
-- sending empty sdlVersion value in RAI response in case out upper bound value in .ini file
RestartSDLChangingSupportedDiagModesValue(self, "OutUpperBoundSdlVersionValue",_, _, "1234567890!@#$%%^&*()_+{}:|<>?[];'\\,./qwertyuiopASDFGHJKLzxcvbnm1234567890!@#$%%^&*()_+{}:|<>?[];'\\,.//")

function Test:OutUpperBoundSdlVersionValueInRAIResponse()
	userPrint(34, "=================================== Test  Case ===================================")

	local RAIResponseParam = {
		success = true,
		resultCode = "SUCCESS",
		sdlVersion = ""
	}

	RegisterApp(self, RAIParams, RAIResponseParam)
end

----------------------------------------------------------------------------
-- sending sdlVersion value in RAI response in case only digits in value in .ini file
RestartSDLChangingSupportedDiagModesValue(self, "OnlyDigitsSdlVersionValue",_, _, "123456")

function Test:OnlyDigitsSdlVersionValueInRAIResponse()
	userPrint(34, "=================================== Test  Case ===================================")

	local RAIResponseParam = {
		success = true,
		resultCode = "SUCCESS",
		sdlVersion = "123456"
	}

	RegisterApp(self, RAIParams, RAIResponseParam)
end

----------------------------------------------------------------------------
-- sending empty sdlVersion value in RAI response in case absence SDLVersion parameter in .ini file
RestartSDLChangingSupportedDiagModesValue(self, "AbsentSdlVersionInIniFile",_, _, ";")

function Test:SdlVersionValueInRAIResponseInIniFileSdlVersionParamIsAbsent()
	userPrint(34, "=================================== Test  Case ===================================")

	local RAIResponseParam = {
		success = true,
		resultCode = "SUCCESS",
		sdlVersion = ""
	}

	RegisterApp(self, RAIParams, RAIResponseParam)
end

----------------------------------------------------------------------------
--Postcondition: Set default values to .ini file
RestartSDLChangingSupportedDiagModesValue(self, "RAI_Postcondition_SetDefaultValues","0x01, 0x02, 0x03, 0x05, 0x06, 0x07, 0x09, 0x0A, 0x18, 0x19, 0x22, 0x3E", _, "{GIT_COMMIT}")



----------------------------------------------------------------------------------------------
----------------------------------------VII TEST BLOCK----------------------------------------
-------------------------Provide supported PCM Stream Capabilities----------------------------
----------------------------------------------------------------------------------------------

-- next test are covers CRQ APPLINK-23057
-- ONLY POSITIVE CASES are assumed as real cases, see question APPLINK-23459
-- next manual test cases are covered by this TestBlock
-- APPLINK-23153	01[HP][MAN]_TC_pcmStreamCapabilities_in_HMI_capabilities.json
-- APPLINK-23162	02[HP][MAN]_TC_pcmStreamCapabilities_in_MOBILE_API.xml
-- APPLINK-23165	03[HP][MAN]_TC_pcmStreamCapabilities_in_RegisterAppInterface_response
--===================================================================================--
-- SDL converts the hex values taken from smartdeviceLink.ini file to integer ones and sends the converted values within supportedDiagModes parameter in response to RegisterAppInterface.
--===================================================================================--


----------------------------------------------------------------------------
-- Common values in supportedDiagModes
-- supportedDiagModes:  minvalue="0", maxvalue="255", minsize="1", maxsize="100"

-- TODO - uncoment entire block VII after implementing dev task APPLINK-23060
local function userPrint( color, message)
  print ("\27[" .. tostring(color) .. "m " .. tostring(message) .. " \27[0m")
end
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
startOfSDLIndex = 1

function SetParameterInJson(pathToFile, samplingRate, bitsPerSample, audioType)
	-- body
	local file  = io.open(pathToFile, "r")
	local json_data = file:read("*all") -- may be abbreviated to "*a";
	file:close()

	local json = require("json")
	 
	local data = json.decode(json_data)
	data.UI.pcmStreamCapabilities.samplingRate = samplingRate
	data.UI.pcmStreamCapabilities.bitsPerSample = bitsPerSample
	data.UI.pcmStreamCapabilities.audioType = audioType
	data = json.encode(data)

	-- print(data)
	file = io.open(pathToFile, "w")
	file:write(data)
	file:close()
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
	-- will be uncommented after fixinf defect: APPLINK-21931
	-- EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered")
	-- :Times(appNumber)

	DelayedExp(1000)
end

local function StartSDLAfterChangeSetting(appNumberForIGNOFF)
	-- body
	local suffix = startOfSDLIndex

	-- Test["Precondition_IGNITION_OFF_" .. tostring(suffix)] = function(self)
	-- 	IGNITION_OFF(self, appNumberForIGNOFF)
	-- end

	Test["Precondition_StartSDL_" .. tostring(suffix)] = function(self)
		StartSDL(config.pathToSDL, config.ExitOnCrash)
	end

	Test["Precondition_InitHMI_" .. tostring(suffix)] = function(self)
		self:initHMI()
	end

	Test["Precondition_InitHMI_onReady_" .. tostring(suffix)] = function(self)
		self:initHMI_onReady()
	end

	Test["Precondition_ConnectMobile_" .. tostring(suffix)] = function(self)
		self:connectMobile()
	end

	Test["Precondition_StartSession_" .. tostring(suffix)] = function(self)
		self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
	end

	startOfSDLIndex = startOfSDLIndex + 1

end

local function RegisterAppForCheckPcmStreamCapabilities(self, passCriteria)
  local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
    -- :Do(function(_,data)
    --   HMIAppID = data.params.application.appID
    --   self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
    -- end)

  -- self.mobileSession:ExpectResponse(correlationId, { success = true })
  EXPECT_RESPONSE(correlationId, { success = true })
  :ValidIf(function (_,data)
  	userPrint(34, "Actual samplingRate: " .. data.payload.pcmStreamCapabilities.samplingRate)
  	userPrint(34, "Actual bitsPerSample: " .. data.payload.pcmStreamCapabilities.bitsPerSample)
  	userPrint(34, "Actual audioType: " .. data.payload.pcmStreamCapabilities.audioType)
  	userPrint(34, "Expected samplingRate: " .. passCriteria.samplingRate)
  	userPrint(34, "Expected bitsPerSample: " .. passCriteria.bitsPerSample)
  	userPrint(34, "Expected audioType: " .. passCriteria.audioType)
    if data.payload.pcmStreamCapabilities.samplingRate == passCriteria.samplingRate and
    	data.payload.pcmStreamCapabilities.bitsPerSample == passCriteria.bitsPerSample and
    	data.payload.pcmStreamCapabilities.audioType == passCriteria.audioType then
      return true
    else
      return false
    end
  end)

end


function Test:GlobalPrecondition(...)
	-- body
	local hmiCapabilitiesName = "hmi_capabilities.json"
	if string.sub(config.pathToSDL, -1) == '/' then
	    --do
	    config.originalHmiCapabilities = string.sub(config.pathToSDL, 1, -5)
	else
		config.originalHmiCapabilities = string.sub(config.pathToSDL, 1, -4)
	end
	config.originalHmiCapabilities = config.originalHmiCapabilities .. "src/appMain/" .. hmiCapabilitiesName
	os.execute("cp " .. config.originalHmiCapabilities .. " " .. config.pathToSDL .. "~" ..hmiCapabilitiesName)
	os.execute("cp " .. config.originalHmiCapabilities .. " " .. config.pathToSDL .. hmiCapabilitiesName)
end


-- test - check that OOTB pcmStreamCapabilities is exactly as requested by Ford
function Test:PreconditionUnregisterAtfApplication()
	--mobile side: UnregisterAppInterface request 
	local CorIdUAI = self.mobileSession:SendRPC("UnregisterAppInterface",{}) 

	--hmi side: expect OnAppUnregistered notification 
	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.applications["SyncProxyTester"], unexpectedDisconnect = false})
 
	 --mobile side: UnregisterAppInterface response 
	EXPECT_RESPONSE(CorIdUAI, { success = true, resultCode = "SUCCESS"})
	:Timeout(2000) 
end

function Test:CheckOOTBpcmCapabilities(...)
	local checkedDefaultPCMCapabilities = {
		samplingRate = "16KHZ",
		bitsPerSample = "16_BIT",
		audioType = "PCM"
	}

	local checkedDefaultAudioPassThruCapabilities = {
		samplingRate = "44KHZ",
		bitsPerSample = "8_BIT",
		audioType = "PCM"
	}

	local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
	-- :Do(function(_,data)
	--   HMIAppID = data.params.application.appID
	--   self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
	-- end)

	-- self.mobileSession:ExpectResponse(correlationId, { success = true })
	EXPECT_RESPONSE(correlationId, { success = true })
	:ValidIf(function (_,data)
		userPrint(34, "Actual PCM samplingRate: " .. data.payload.pcmStreamCapabilities.samplingRate)
		userPrint(34, "Expected PCM samplingRate: " .. checkedDefaultPCMCapabilities.samplingRate)
		userPrint(34, "Actual PCM bitsPerSample: " .. data.payload.pcmStreamCapabilities.bitsPerSample)
		userPrint(34, "Expected PCM bitsPerSample: " .. checkedDefaultPCMCapabilities.bitsPerSample)
		userPrint(34, "Actual PCM audioType: " .. data.payload.pcmStreamCapabilities.audioType)
		userPrint(34, "Expected PCM audioType: " .. checkedDefaultPCMCapabilities.audioType)
		userPrint(34, "Actual AudioPassThru samplingRate: " .. data.payload.audioPassThruCapabilities[1].samplingRate)
		userPrint(34, "Expected AudioPassThru samplingRate: " .. checkedDefaultAudioPassThruCapabilities.samplingRate)
		userPrint(34, "Actual AudioPassThru bitsPerSample: " .. data.payload.audioPassThruCapabilities[1].bitsPerSample)
		userPrint(34, "Expected AudioPassThru bitsPerSample: " .. checkedDefaultAudioPassThruCapabilities.bitsPerSample)
		userPrint(34, "Actual AudioPassThru audioType: " .. data.payload.audioPassThruCapabilities[1].audioType)
		userPrint(34, "Expected AudioPassThru audioType: " .. checkedDefaultAudioPassThruCapabilities.audioType)
	if data.payload.pcmStreamCapabilities.samplingRate == checkedDefaultPCMCapabilities.samplingRate and
		data.payload.pcmStreamCapabilities.bitsPerSample == checkedDefaultPCMCapabilities.bitsPerSample and
		data.payload.pcmStreamCapabilities.audioType == checkedDefaultPCMCapabilities.audioType and 
		data.payload.audioPassThruCapabilities[1].samplingRate == checkedDefaultAudioPassThruCapabilities.samplingRate and
		data.payload.audioPassThruCapabilities[1].bitsPerSample == checkedDefaultAudioPassThruCapabilities.bitsPerSample and
		data.payload.audioPassThruCapabilities[1].audioType == checkedDefaultAudioPassThruCapabilities.audioType then
	  return true
	else
	  return false
	end
	end)
end

-- local json = require("json")

local checkedCapabilities = {
	samplingRate = "16KHZ",
	bitsPerSample = "16_BIT",
	audioType = "PCM"
}

samplingRateEnum = {"8KHZ", "16KHZ", "22KHZ", "44KHZ"}
samplingRateEnumInternal = {"RATE_8KHZ", "RATE_16KHZ", "RATE_22KHZ", "RATE_44KHZ"}
bitsPerSampleEnum = {"8_BIT", "16_BIT"}
bitsPerSampleEnumInternal = {"RATE_8_BIT", "RATE_16_BIT"}
audioTypeEnum = {"PCM"}

for keySample, smplRate in pairs(samplingRateEnum) do
	for keyBits, btsPrSmpl in pairs(bitsPerSampleEnum) do
		for keyAudioType, adTp in pairs(audioTypeEnum) do

			-- stop SDL
			function Test:StopSDL(...)
				-- body
				IGNITION_OFF(self, 1)
				DelayedExp(1000)
			end

			-- precondition: set new positive parameter
			function Test:SetNewParam(...)
				-- body
				local hmiCapabilitiesName = "hmi_capabilities.json"
				userPrint(34, "samplingRate: " .. smplRate)
				userPrint(34, "bitsPerSample: " .. btsPrSmpl)

				checkedCapabilities.samplingRate = smplRate
				checkedCapabilities.bitsPerSample = btsPrSmpl
				checkedCapabilities.audioType = adTp

				SetParameterInJson(config.pathToSDL .. hmiCapabilitiesName, smplRate, btsPrSmpl, adTp)
				os.execute("sleep 0.5")
			end

			StartSDLAfterChangeSetting(1)

			-- test: check that SDL repsonses with new pcmStreamCapabilities
			function Test:CheckPcmStreamCapabilities(...)
				-- body
				self.mobileSession:StartService(7)
				:Do(function (_,data)
					RegisterAppForCheckPcmStreamCapabilities(self, checkedCapabilities)
				end)
			end
		end
	end
end

for keySample, smplRate in pairs(samplingRateEnum) do
	for keyBits, btsPrSmpl in pairs(bitsPerSampleEnumInternal) do
		for keyAudioType, adTp in pairs(audioTypeEnum) do

			-- stop SDL
			function Test:StopSDL(...)
				-- body
				IGNITION_OFF(self, 1)
				DelayedExp(1000)
			end

			-- precondition: set new positive parameter
			function Test:SetNewParam(...)
				-- body
				local hmiCapabilitiesName = "hmi_capabilities.json"
				userPrint(34, "samplingRate: " .. smplRate)
				userPrint(34, "bitsPerSample: " .. btsPrSmpl)

				checkedCapabilities.samplingRate = smplRate
				checkedCapabilities.bitsPerSample = btsPrSmpl
				checkedCapabilities.audioType = adTp

				SetParameterInJson(config.pathToSDL .. hmiCapabilitiesName, smplRate, btsPrSmpl, adTp)
				os.execute("sleep 0.5")
			end

			StartSDLAfterChangeSetting(1)

			-- test: check that SDL repsonses with new pcmStreamCapabilities
			function Test:CheckPcmStreamCapabilities(...)
				-- body
				self.mobileSession:StartService(7)
				:Do(function (_,data)
					checkedCapabilities.bitsPerSample = string.sub(checkedCapabilities.bitsPerSample, 6)
					RegisterAppForCheckPcmStreamCapabilities(self, checkedCapabilities)
				end)
			end
		end
	end
end

for keySample, smplRate in pairs(samplingRateEnumInternal) do
	for keyBits, btsPrSmpl in pairs(bitsPerSampleEnum) do
		for keyAudioType, adTp in pairs(audioTypeEnum) do

			-- stop SDL
			function Test:StopSDL(...)
				-- body
				IGNITION_OFF(self, 1)
				DelayedExp(1000)
			end

			-- precondition: set new positive parameter
			function Test:SetNewParam(...)
				-- body
				local hmiCapabilitiesName = "hmi_capabilities.json"
				userPrint(34, "samplingRate: " .. smplRate)
				userPrint(34, "bitsPerSample: " .. btsPrSmpl)

				checkedCapabilities.samplingRate = smplRate
				checkedCapabilities.bitsPerSample = btsPrSmpl
				checkedCapabilities.audioType = adTp

				SetParameterInJson(config.pathToSDL .. hmiCapabilitiesName, smplRate, btsPrSmpl, adTp)
				os.execute("sleep 0.5")
			end

			StartSDLAfterChangeSetting(1)

			-- test: check that SDL repsonses with new pcmStreamCapabilities
			function Test:CheckPcmStreamCapabilities(...)
				-- body
				self.mobileSession:StartService(7)
				:Do(function (_,data)
					checkedCapabilities.samplingRate = string.sub(checkedCapabilities.samplingRate, 6)
					RegisterAppForCheckPcmStreamCapabilities(self, checkedCapabilities)
				end)
			end
		end
	end
end

for keySample, smplRate in pairs(samplingRateEnumInternal) do
	for keyBits, btsPrSmpl in pairs(bitsPerSampleEnumInternal) do
		for keyAudioType, adTp in pairs(audioTypeEnum) do

			-- stop SDL
			function Test:StopSDL(...)
				-- body
				IGNITION_OFF(self, 1)
				DelayedExp(1000)
			end

			-- precondition: set new positive parameter
			function Test:SetNewParam(...)
				-- body
				local hmiCapabilitiesName = "hmi_capabilities.json"
				userPrint(34, "samplingRate: " .. smplRate)
				userPrint(34, "bitsPerSample: " .. btsPrSmpl)

				checkedCapabilities.samplingRate = smplRate
				checkedCapabilities.bitsPerSample = btsPrSmpl
				checkedCapabilities.audioType = adTp

				SetParameterInJson(config.pathToSDL .. hmiCapabilitiesName, smplRate, btsPrSmpl, adTp)
				os.execute("sleep 0.5")
			end

			StartSDLAfterChangeSetting(1)

			-- test: check that SDL repsonses with new pcmStreamCapabilities
			function Test:CheckPcmStreamCapabilities(...)
				-- body
				self.mobileSession:StartService(7)
				:Do(function (_,data)
					checkedCapabilities.samplingRate = string.sub(checkedCapabilities.samplingRate, 6)
					checkedCapabilities.bitsPerSample = string.sub(checkedCapabilities.bitsPerSample, 6)
					RegisterAppForCheckPcmStreamCapabilities(self, checkedCapabilities)
				end)
			end
		end
	end
end

function Test:Postcondition(...)
	-- body
	local hmiCapabilitiesName = "hmi_capabilities.json"
	os.execute("cp " .. config.pathToSDL .. "~" ..hmiCapabilitiesName .. " " .. config.pathToSDL .. hmiCapabilitiesName)
end

-- Postcondition: restoring sdl_preloaded_pt file
-- TODO: Remove after implementation policy update
function Test:Postcondition_Preloadedfile()
  print ("restoring sdl_preloaded_pt.json")
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end

return Test
----------------------------------------------------------------------------------------------
----------------------------------------VII TEST BLOCK----------------------------------------
---------------------------------------------END----------------------------------------------
----------------------------------------------------------------------------------------------






