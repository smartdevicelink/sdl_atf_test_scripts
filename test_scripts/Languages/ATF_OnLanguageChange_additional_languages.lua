--------------------------------------------------------------------------------
-- Preconditions before ATF start
--------------------------------------------------------------------------------
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
--------------------------------------------------------------------------------
--Precondition: preparation connecttest_languages.lua
commonPreconditions:Connecttest_Languages_update("connecttest_languages.lua", true)

Test = require('user_modules/connecttest_languages')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local mobile  = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')
require('user_modules/AppTypes')

local iTimeout = 5000


config.deviceMAC      = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
config.SDLStoragePath = config.pathToSDL .."storage/"
--ToDo: shall be removed when APPLINK-16610 is fixed
config.defaultProtocolVersion = 2

local strAppFolder = config.SDLStoragePath..config.application1.registerAppInterfaceParams.fullAppID.. "_" .. config.deviceMAC.. "/"



---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------
	--Begin Precondition.1
	--Description: Activation App by sending SDL.ActivateApp


		function Test:ActivateApplication()
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

						EXPECT_HMICALL("BasicCommunication.ActivateApp")
						:Do(function(_,data)
							self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
						end)
						:Times(2)
					end)

				end
			end)

			EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL"}) 

		end

	--End Precondition.1

	-----------------------------------------------------------------------------------------

	-- Precondition: removing user_modules/connecttest_languages.lua
	function Test:Precondition_remove_user_connecttest()
	  os.execute( "rm -f ./user_modules/connecttest_languages.lua" )
	end

---------------------------------------------------------------------------------------------
-----------------------------------------I TEST BLOCK----------------------------------------
--CommonRequestCheck: Check new additional languages according to CRQ APPLINK-13745 ---------
---------------------------------------------------------------------------------------------


--Begin test suit CommonRequestCheck.1
--Description: Checking UI.OnLanguageChange notification from HMI and correct sending notifacation to mobile. Unregistering app with reason "LANGUAGE_CHANGE"

--Begin test case CommonRequestCheck.1.1
--Description: Check language EL-GR

	function Test:UI_OnLanguageChange_EL_GR()
				  
					--hmi side: expect UI.OnLanguageChange notification
					self.hmiConnection:SendNotification("UI.OnLanguageChange", {language = "EL-GR"})


					--hmi side: expect BasicCommunication.OnSystemInfoChanged request
					self.hmiConnection:SendNotification("BasicCommunication.OnSystemInfoChanged", {language = "EL-GR"})


					--mobile side: expect OnLanguageChange notification
					EXPECT_NOTIFICATION("OnLanguageChange", {hmiDisplayLanguage = "EL-GR", language = "EN-US"}) 


					--mobile side: expect OnAppInterfaceUnregistered notification
					EXPECT_NOTIFICATION("OnAppInterfaceUnregistered", {reason = "LANGUAGE_CHANGE"}) 
					:Timeout(2000)
	end

--End test case CommonRequestCheck.1.1
-----------------------------------------------------------------------------------------


--Begin test case CommonRequestCheck.1.2
--Description: Check language NL-BE

--Begin Precondition
--Description: Registration app

function Test:RegisterAppInterface_precondition() 

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
																	languageDesired ="EN-US",
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
						     --            	deviceInfo = 
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
					EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
						:Timeout(2000)
						:Do(function(_,data)

							EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE"})

						end)

				end

	function Test:UI_OnLanguageChange_NL_BE()
				  
					--hmi side: expect UI.OnLanguageChange notification
					self.hmiConnection:SendNotification("UI.OnLanguageChange", {language = "NL-BE"})


					--hmi side: expect BasicCommunication.OnSystemInfoChanged request
					self.hmiConnection:SendNotification("BasicCommunication.OnSystemInfoChanged", {language = "NL-BE"})


					--mobile side: expect OnLanguageChange notification
					EXPECT_NOTIFICATION("OnLanguageChange", {hmiDisplayLanguage = "NL-BE", language = "EN-US"}) 


					--mobile side: expect OnAppInterfaceUnregistered notification
					EXPECT_NOTIFICATION("OnAppInterfaceUnregistered", {reason = "LANGUAGE_CHANGE"}) 
					:Timeout(5000)
	end

--End test case CommonRequestCheck.1.2
-----------------------------------------------------------------------------------------

--Begin test case CommonRequestCheck.1.3
--Description: Check language HU-HU

--Begin Precondition
--Description: Registration app

function Test:RegisterAppInterface_precondition() 

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
																	languageDesired ="EN-US",
																	hmiDisplayLanguageDesired ="NL-BE",
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
						     --            	deviceInfo = 
											-- {
											-- 	hardware = "hardware",
											-- 	firmwareRev = "firmwareRev",
											-- 	os = "os",
											-- 	osVersion = "osVersion",
											-- 	carrier = "carrier",
											-- 	maxNumberRFCOMMPorts = 5
											-- },
											policyAppID = "123456",
											hmiDisplayLanguageDesired ="NL-BE",
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
					EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
						:Timeout(2000)
						:Do(function(_,data)

							EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE"})

						end)

				end

	function Test:UI_OnLanguageChange_HU_HU()
				  
					--hmi side: expect UI.OnLanguageChange notification
					self.hmiConnection:SendNotification("UI.OnLanguageChange", {language = "HU-HU"})


					--hmi side: expect BasicCommunication.OnSystemInfoChanged request
					self.hmiConnection:SendNotification("BasicCommunication.OnSystemInfoChanged", {language = "HU-HU"})


					--mobile side: expect OnLanguageChange notification
					EXPECT_NOTIFICATION("OnLanguageChange", {hmiDisplayLanguage = "HU-HU", language = "EN-US"}) 


					--mobile side: expect OnAppInterfaceUnregistered notification
					EXPECT_NOTIFICATION("OnAppInterfaceUnregistered", {reason = "LANGUAGE_CHANGE"}) 
					:Timeout(2000)
	end

--End test case CommonRequestCheck.1.3
-----------------------------------------------------------------------------------------

--Begin test case CommonRequestCheck.1.4
--Description: Check language FI-FI

--Begin Precondition
--Description: Registration app

function Test:RegisterAppInterface_precondition() 

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
																	languageDesired ="EN-US",
																	hmiDisplayLanguageDesired ="HU-HU",
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
						     --            	deviceInfo = 
											-- {
											-- 	hardware = "hardware",
											-- 	firmwareRev = "firmwareRev",
											-- 	os = "os",
											-- 	osVersion = "osVersion",
											-- 	carrier = "carrier",
											-- 	maxNumberRFCOMMPorts = 5
											-- },
											policyAppID = "123456",
											hmiDisplayLanguageDesired ="HU-HU",
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
					EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
						:Timeout(2000)
						:Do(function(_,data)

							EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE"})

						end)

				end

	function Test:UI_OnLanguageChange_FI_FI()
				  
					--hmi side: expect UI.OnLanguageChange notification
					self.hmiConnection:SendNotification("UI.OnLanguageChange", {language = "FI-FI"})


					--hmi side: expect BasicCommunication.OnSystemInfoChanged request
					self.hmiConnection:SendNotification("BasicCommunication.OnSystemInfoChanged", {language = "FI-FI"})


					--mobile side: expect OnLanguageChange notification
					EXPECT_NOTIFICATION("OnLanguageChange", {hmiDisplayLanguage = "FI-FI", language = "EN-US"}) 


					--mobile side: expect OnAppInterfaceUnregistered notification
					EXPECT_NOTIFICATION("OnAppInterfaceUnregistered", {reason = "LANGUAGE_CHANGE"}) 
					:Timeout(2000)
	end

--End test case CommonRequestCheck.1.4
-----------------------------------------------------------------------------------------

--Begin test case CommonRequestCheck.1.5
--Description: Check language FI-FI

--Begin Precondition
--Description: Registration app

function Test:RegisterAppInterface_precondition() 

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
																	languageDesired ="EN-US",
																	hmiDisplayLanguageDesired ="FI-FI",
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
						     --            	deviceInfo = 
											-- {
											-- 	hardware = "hardware",
											-- 	firmwareRev = "firmwareRev",
											-- 	os = "os",
											-- 	osVersion = "osVersion",
											-- 	carrier = "carrier",
											-- 	maxNumberRFCOMMPorts = 5
											-- },
											policyAppID = "123456",
											hmiDisplayLanguageDesired ="FI-FI",
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
					EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
						:Timeout(2000)
						:Do(function(_,data)

							EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE"})

						end)

				end

	function Test:UI_OnLanguageChange_SK_SK()
				  
					--hmi side: expect UI.OnLanguageChange notification
					self.hmiConnection:SendNotification("UI.OnLanguageChange", {language = "SK-SK"})


					--hmi side: expect BasicCommunication.OnSystemInfoChanged request
					self.hmiConnection:SendNotification("BasicCommunication.OnSystemInfoChanged", {language = "SK-SK"})


					--mobile side: expect OnLanguageChange notification
					EXPECT_NOTIFICATION("OnLanguageChange", {hmiDisplayLanguage = "SK-SK", language = "EN-US"}) 


					--mobile side: expect OnAppInterfaceUnregistered notification
					EXPECT_NOTIFICATION("OnAppInterfaceUnregistered", {reason = "LANGUAGE_CHANGE"}) 
					:Timeout(2000)
	end

--End test case CommonRequestCheck.1.5
--Emd test suit CommonRequestCheck.1
-----------------------------------------------------------------------------------------

--Begin test suit CommonRequestCheck.2
--Description: Checking VR.OnLanguageChange notification from HMI and correct sending notifacation to mobile. Unregistering app with reason "LANGUAGE_CHANGE"

--Begin test case CommonRequestCheck.2.1
--Description: Check language EL-GR

function Test:RegisterAppInterface_precondition() 

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
																	languageDesired ="EN-US",
																	hmiDisplayLanguageDesired ="SK-SK",
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
						     --            	deviceInfo = 
											-- {
											-- 	hardware = "hardware",
											-- 	firmwareRev = "firmwareRev",
											-- 	os = "os",
											-- 	osVersion = "osVersion",
											-- 	carrier = "carrier",
											-- 	maxNumberRFCOMMPorts = 5
											-- },
											policyAppID = "123456",
											hmiDisplayLanguageDesired ="SK-SK",
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
					EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
						:Timeout(2000)
						:Do(function(_,data)

							EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE"})

						end)

				end

	function Test:VR_OnLanguageChange_EL_GR()
				  
					--hmi side: expect VR.OnLanguageChange notification
					self.hmiConnection:SendNotification("VR.OnLanguageChange", {language = "EL-GR"})


					--hmi side: expect BasicCommunication.OnSystemInfoChanged request
					self.hmiConnection:SendNotification("BasicCommunication.OnSystemInfoChanged", {language = "EL-GR"})


					--mobile side: expect OnLanguageChange notification
					EXPECT_NOTIFICATION("OnLanguageChange", {hmiDisplayLanguage = "SK-SK", language = "EL-GR"}) 


					--mobile side: expect OnAppInterfaceUnregistered notification
					EXPECT_NOTIFICATION("OnAppInterfaceUnregistered", {reason = "LANGUAGE_CHANGE"}) 
					:Timeout(2000)
	end

--End test case CommonRequestCheck.2.1
-----------------------------------------------------------------------------------------


--Begin test case CommonRequestCheck.2.2
--Description: Check language NL-BE

--Begin Precondition
--Description: Registration app

function Test:RegisterAppInterface_precondition() 

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
																	hmiDisplayLanguageDesired ="SK-SK",
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
						     --            	deviceInfo = 
											-- {
											-- 	hardware = "hardware",
											-- 	firmwareRev = "firmwareRev",
											-- 	os = "os",
											-- 	osVersion = "osVersion",
											-- 	carrier = "carrier",
											-- 	maxNumberRFCOMMPorts = 5
											-- },
											policyAppID = "123456",
											hmiDisplayLanguageDesired ="SK-SK",
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
					EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
						:Timeout(2000)
						:Do(function(_,data)

							EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE"})

						end)

				end

	function Test:VR_OnLanguageChange_NL_BE()
				  
					--hmi side: expect VR.OnLanguageChange notification
					self.hmiConnection:SendNotification("VR.OnLanguageChange", {language = "NL-BE"})


					--hmi side: expect BasicCommunication.OnSystemInfoChanged request
					self.hmiConnection:SendNotification("BasicCommunication.OnSystemInfoChanged", {language = "NL-BE"})


					--mobile side: expect OnLanguageChange notification
					EXPECT_NOTIFICATION("OnLanguageChange", {hmiDisplayLanguage = "SK-SK", language = "NL-BE"}) 


					--mobile side: expect OnAppInterfaceUnregistered notification
					EXPECT_NOTIFICATION("OnAppInterfaceUnregistered", {reason = "LANGUAGE_CHANGE"}) 
					:Timeout(5000)
	end

--End test case CommonRequestCheck.2.2
-----------------------------------------------------------------------------------------

--Begin test case CommonRequestCheck.2.3
--Description: Check language HU-HU

--Begin Precondition
--Description: Registration app

function Test:RegisterAppInterface_precondition() 

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
																	languageDesired ="NL-BE",
																	hmiDisplayLanguageDesired ="SK-SK",
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
						     --            	deviceInfo = 
											-- {
											-- 	hardware = "hardware",
											-- 	firmwareRev = "firmwareRev",
											-- 	os = "os",
											-- 	osVersion = "osVersion",
											-- 	carrier = "carrier",
											-- 	maxNumberRFCOMMPorts = 5
											-- },
											policyAppID = "123456",
											hmiDisplayLanguageDesired ="SK-SK",
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
					EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
						:Timeout(2000)
						:Do(function(_,data)

							EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE"})

						end)

				end

	function Test:VR_OnLanguageChange_HU_HU()
				  
					--hmi side: expect VR.OnLanguageChange notification
					self.hmiConnection:SendNotification("VR.OnLanguageChange", {language = "HU-HU"})


					--hmi side: expect BasicCommunication.OnSystemInfoChanged request
					self.hmiConnection:SendNotification("BasicCommunication.OnSystemInfoChanged", {language = "HU-HU"})


					--mobile side: expect OnLanguageChange notification
					EXPECT_NOTIFICATION("OnLanguageChange", {hmiDisplayLanguage = "SK-SK", language = "HU-HU"}) 


					--mobile side: expect OnAppInterfaceUnregistered notification
					EXPECT_NOTIFICATION("OnAppInterfaceUnregistered", {reason = "LANGUAGE_CHANGE"}) 
					:Timeout(2000)
	end

--End test case CommonRequestCheck.2.3
-----------------------------------------------------------------------------------------

--Begin test case CommonRequestCheck.2.4
--Description: Check language FI-FI

--Begin Precondition
--Description: Registration app

function Test:RegisterAppInterface_precondition() 

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
																	languageDesired ="HU-HU",
																	hmiDisplayLanguageDesired ="SK-SK",
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
						     --            	deviceInfo = 
											-- {
											-- 	hardware = "hardware",
											-- 	firmwareRev = "firmwareRev",
											-- 	os = "os",
											-- 	osVersion = "osVersion",
											-- 	carrier = "carrier",
											-- 	maxNumberRFCOMMPorts = 5
											-- },
											policyAppID = "123456",
											hmiDisplayLanguageDesired ="SK-SK",
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
					EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
						:Timeout(2000)
						:Do(function(_,data)

							EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE"})

						end)

				end

	function Test:VR_OnLanguageChange_FI_FI()
				  
					--hmi side: expect VR.OnLanguageChange notification
					self.hmiConnection:SendNotification("VR.OnLanguageChange", {language = "FI-FI"})


					--hmi side: expect BasicCommunication.OnSystemInfoChanged request
					self.hmiConnection:SendNotification("BasicCommunication.OnSystemInfoChanged", {language = "FI-FI"})


					--mobile side: expect OnLanguageChange notification
					EXPECT_NOTIFICATION("OnLanguageChange", {hmiDisplayLanguage = "SK-SK", language = "FI-FI"}) 


					--mobile side: expect OnAppInterfaceUnregistered notification
					EXPECT_NOTIFICATION("OnAppInterfaceUnregistered", {reason = "LANGUAGE_CHANGE"}) 
					:Timeout(2000)
	end

--End test case CommonRequestCheck.2.4
-----------------------------------------------------------------------------------------

--Begin test case CommonRequestCheck.2.5
--Description: Check language FI-FI

--Begin Precondition
--Description: Registration app

function Test:RegisterAppInterface_precondition() 

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
																	languageDesired ="FI-FI",
																	hmiDisplayLanguageDesired ="SK-SK",
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
						     --            	deviceInfo = 
											-- {
											-- 	hardware = "hardware",
											-- 	firmwareRev = "firmwareRev",
											-- 	os = "os",
											-- 	osVersion = "osVersion",
											-- 	carrier = "carrier",
											-- 	maxNumberRFCOMMPorts = 5
											-- },
											policyAppID = "123456",
											hmiDisplayLanguageDesired ="SK-SK",
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
					EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
						:Timeout(2000)
						:Do(function(_,data)

							EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE"})

						end)

				end

	function Test:VR_OnLanguageChange_SK_SK()
				  
					--hmi side: expect VR.OnLanguageChange notification
					self.hmiConnection:SendNotification("VR.OnLanguageChange", {language = "SK-SK"})


					--hmi side: expect BasicCommunication.OnSystemInfoChanged request
					self.hmiConnection:SendNotification("BasicCommunication.OnSystemInfoChanged", {language = "SK-SK"})


					--mobile side: expect OnLanguageChange notification
					EXPECT_NOTIFICATION("OnLanguageChange", {hmiDisplayLanguage = "SK-SK", language = "SK-SK"}) 


					--mobile side: expect OnAppInterfaceUnregistered notification
					EXPECT_NOTIFICATION("OnAppInterfaceUnregistered", {reason = "LANGUAGE_CHANGE"}) 
	end

--End test case CommonRequestCheck.2.5
-----------------------------------------------------------------------------------------
