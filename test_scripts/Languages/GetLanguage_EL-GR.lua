--------------------------------------------------------------------------------
-- Preconditions before ATF start
--------------------------------------------------------------------------------
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
  
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

    os.execute("rm -r " ..config.pathToSDL .. "storage")
end

DeleteLog_app_info_dat_policy()

--------------------------------------------------------------------------------
--Precondition: preparation connecttest_languages.lua
commonPreconditions:Connecttest_Languages_update("connecttest_languages.lua", true)

Test = require('user_modules/connecttest_languages')
local events = require('events')
local mobile_session = require('mobile_session')
require('user_modules/AppTypes')



local hmi_connection = require('hmi_connection')
local websocket      = require('websocket_connection')
local module         = require('testbase')
local mobile  = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')

config.deviceMAC      = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
--ToDo: shall be removed when APPLINK-16610 is fixed
config.defaultProtocolVersion = 2

local function OpenConnectionCreateSession(self)
	local tcpConnection = tcp.Connection(config.mobileHost, config.mobilePort)
	local fileConnection = file_connection.FileConnection("mobile.out", tcpConnection)
	self.mobileConnection = mobile.MobileConnection(fileConnection)
	self.mobileSession= mobile_session.MobileSession(
	self.expectations_list,
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

-- Precondition: removing user_modules/connecttest_languages.lua
	function Test:Precondition_remove_user_connecttest()
	  os.execute( "rm -f ./user_modules/connecttest_languages.lua" )
	end



---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------
	--Begin Precondition.1
	--Description:Activation app

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
	    			  	EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
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
	  	EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL"})	

	end

	--End Precondition.1

	--ToDo 1: Shall be uncommented when APPLINK-25363: [Genivi]Service ID for endpoints are incorrectly written in DB in specific case
	--ToDo 2: Shall be checked is there a need of Precondition.2
	--Begin Precondition.2
	--Description: Policy update for RegisterAppInterface API
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
	-- 				fileName = "PolicyTableUpdate"
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
	-- 				print("BasicCommunication.SystemRequest is received")
					
	-- 				-- hmi side: sending BasicCommunication.OnSystemRequest request to SDL
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
	-- 			EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", { status =  "UP_TO_DATE"})
	-- 			:Do(function(_,data)
	-- 				print("SDL.OnStatusUpdate is received")			               
	-- 			end)
	-- 			:Timeout(2000)
				
	-- 			--mobile side: expect SystemRequest response
	-- 			EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
	-- 			:Do(function(_,data)
	-- 				print("SystemRequest is received")
	-- 				--hmi side: sending SDL.GetUserFriendlyMessage request to SDL
	-- 				local RequestIdGetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"StatusUpToDate"}})
					
	-- 				--hmi side: expect SDL.GetUserFriendlyMessage response
	-- 				EXPECT_HMIRESPONSE(RequestIdGetUserFriendlyMessage,{result = {code = 0, method = "SDL.GetUserFriendlyMessage", messages = {{line1 = "Up-To-Date", messageCode = "StatusUpToDate", textBody = "Up-To-Date"}}}})
	-- 				:Do(function(_,data)
	-- 					print("SDL.GetUserFriendlyMessage is received")                    
	-- 				end)
	-- 			end)
	-- 			:Timeout(2000)
				
	-- 		end)
	-- 	end)	
	-- end	
	-- --End Precondition.2

	--Begin Precondition.3
	--Description: The application should be unregistered before next test.

		function Test:UnregisterAppInterface_Success() 

			UnregisterApplicationSessionOne(self)

		end

	--End Precondition.3




---------------------------------------------------------------------------------------------
-----------------------------------------I TEST BLOCK----------------------------------------
--------------------------------------CommonRequestCheck: Check that app correctly registers with "NL-BE" language. "EL-GR" language was got by GetLanguage" in connecttest_"EL-GR"-----------------------------------
---------------------------------------------------------------------------------------------

	--UPDATED: according to APPLINK-16249
	--Begin Test suit CommonRequestCheck
	--TODO: Test is checked CRQ APPLINK-13745 - additional languages "NL-BE", "EL-GR", "HU-HU", "FI-FI", "SK-SK". For new ATF version need to create test to check all languages in one script
		

				function Test:RegisterAppInterface_EL_GR() 

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
																	isMediaApplication = true,
																	languageDesired ="EL-GR",
																	hmiDisplayLanguageDesired ="EL-GR",
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
						                	--ToDo: Shall be uncommented when APPLINK-16052 "ATF: TC is failed in case receiving message with nested struct" is fixed
						                	--UPDATED
                              				-- deviceInfo = 
                              				-- {
                              				--     transportType = "WIFI",
                              				--     isSDLAllowed = true,
                              				--     id = config.deviceMAC,
                              				--     name = "127.0.0.1"
                              				-- },
						                 	-- deviceInfo = 
											-- {
											-- 	hardware = "hardware",
											-- 	firmwareRev = "firmwareRev",
											-- 	os = "os",
											-- 	osVersion = "osVersion",
											-- 	carrier = "carrier",
											-- 	maxNumberRFCOMMPorts = 5
											-- },
											policyAppID = "123456",
											hmiDisplayLanguageDesired ="EL-GR",
											isMediaApplication = true,
											--UPDATED
											-- appHMIType = 
											appType = 
											{ 
												"DEFAULT"
											},
											-- requestType = 
											-- {

											-- }
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
					EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "WRONG_LANGUAGE"})
						:Timeout(2000)
						:Do(function(_,data)

							EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE"})

						end)



				end