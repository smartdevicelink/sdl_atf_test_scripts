---------------------------------------------------------------------------------------------
--ATF version: 2.2
--Modified date: 01/Dec/2015
--Author: Ta Thanh Dong
---------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Preconditions
--------------------------------------------------------------------------------
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

--------------------------------------------------------------------------------
--Precondition: preparation connecttest_OnAppUnregistered.lua
commonPreconditions:Connecttest_without_ExitBySDLDisconnect("connecttest_OnAppUnregistered.lua")

config.defaultProtocolVersion = 3

        function Precondition_ArchivateINI()
	    commonPreconditions:BackupFile("smartDeviceLink.ini")
	end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

Test = require('user_modules/connecttest_OnAppUnregistered')
local mobile_session = require('mobile_session')
local mobile = require("mobile_connection")
local tcp = require("tcp_connection")
local file_connection = require("file_connection")
require('cardinalities')
local events = require('events')

---------------------------------------------------------------------------------------------
-----------------------------Required Shared Libraries---------------------------------------
---------------------------------------------------------------------------------------------
require('user_modules/AppTypes')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local policyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')

config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

local appIDAndDeviceMac = config.application1.registerAppInterfaceParams.fullAppID.. "_" .. config.deviceMAC.. "/"
local storagePath = config.pathToSDL .. "storage/" .. config.application1.registerAppInterfaceParams.fullAppID .. "_" .. config.deviceMAC .. "/"
local strAppFolder = storagePath..appIDAndDeviceMac
local strIvsu_cacheFolder = "/tmp/fs/mp/images/ivsu_cache/"


---------------------------------------------------------------------------------------------
------------------------------------ Common Variables ---------------------------------------
---------------------------------------------------------------------------------------------

APIName = "OnAppUnregistered" -- set request name

---------------------------------------------------------------------------------------------



NewTestSuiteNumber = 0 -- use as subfix of test case "NewTestSuite" to make different test case name.


local function startSession(self)

	self.mobileSession= mobile_session.MobileSession(self, self.mobileConnection)

	--configure HB and protocol
	self.mobileSession.version = 3
	self.mobileSession:SetHeartbeatTimeout(7000)

	--start session
	self.mobileSession:StartService(7)
	--start HB in case you need and protocol version is 3
    self.mobileSession:StartHeartbeat()

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

---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------

		--Print new line to separate Preconditions
	commonFunctions:newTestCasesGroup("Preconditions")

	--1. Delete policy table
	commonSteps:DeletePolicyTable()

	--2. Delete app_info.dat and log files
	os.remove(config.pathToSDL .. "app_info.dat")
	os.remove(config.pathToSDL .. "*.log")


	--3. Update policy to allow request
	--TODO: Will be updated after policy flow implementation
	policyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/PTU_ForOnAppUnregistered_05.json")

	--4. removing user_modules/connecttest_OnAppUnregistered.lua
	function Test:Precondition_remove_user_connecttest()
	 	os.execute( "rm -f ./user_modules/connecttest_OnAppUnregistered.lua" )
	end


	--Print new line to separate test suite
	commonFunctions:newTestCasesGroup("Test Suite For TCs")
---------------------------------------------------------------------------------------------
--SDLAQ-TC-423: TC_OnAppUnregistered_01:
--APPLINK-16314: 23[P][MAN]_TC_OnAppUnregistered_after_HB_timeout_disconnection
---------------------------------------------------------------------------------------------


	local function TC_OnAppUnregistered_01()

		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup("Test case: TC_OnAppUnregistered_01, 23[P][MAN]_TC_OnAppUnregistered_after_HB_timeout_disconnection")

		--Precondition
		function Test:Unregister_Application_01()

			local cid = self.mobileSession:SendRPC("UnregisterAppInterface",{})

			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
			:Timeout(2000)
		end

		function Test:Register_App_Interface_And_Store_appID_01()

			--mobile side: send RegisterAppInterface request
			local CorIdRegister = self.mobileSession:SendRPC("RegisterAppInterface", {
																						syncMsgVersion =
																						{
																						  majorVersion = 3,
																						  minorVersion = 1
																						},
																						appName = "SPTtest",
																						isMediaApplication = false,
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

			--hmi side: expect BasicCommunication.OnAppRegistered request
			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
			{
				application =
				{
					appName = "SPTtest",
					policyAppID = "1234567"
				}
			})
			:Do(function(_,data)
				self.applications["SPTtest"] = data.params.application.appID
			end)

			--mobile side: expect response
			self.mobileSession:ExpectResponse(CorIdRegister, {success = true, resultCode = "SUCCESS"})

			--mobile side: expect notification
			self.mobileSession:ExpectNotification("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})

		end

		function Test:IgnoreHeartbeatOnMobile_01()
			self.mobileSession.sendHeartbeatToSDL = false
			self.mobileSession.answerHeartbeatFromSDL = false
		end

		function Test:Wait_14_seconds_And_Verify_OnAppUnregistered_01()

			--hmi side: expect BasicCommunication.OnAppUnregistered
			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.applications["SPTtest"], unexpectedDisconnect =  true})
			:Timeout(15000)
			:Do(function()
				self.mobileSession:StopHeartbeat()
			end)

		end

		function Test:ConnectMobileAgain_01()
			--self:connectMobile()
			local tcpConnection = tcp.Connection(config.mobileHost, config.mobilePort)
			local fileConnection = file_connection.FileConnection("mobile.out", tcpConnection)
			self.mobileConnection = mobile.MobileConnection(fileConnection)
			self.mobileSession= mobile_session.MobileSession(
			self,
			self.mobileConnection)
			event_dispatcher:AddConnection(self.mobileConnection)
			self.mobileSession:ExpectEvent(events.connectedEvent, "Connection started")
			self.mobileConnection:Connect()
		end

		function Test:StartSession_01()
		  startSession(self)
		end

		function Test:Register_App_Interface_Again_And_Verify_appID_Is_Not_Changed_01()


			local CorIdRegister = self.mobileSession:SendRPC("RegisterAppInterface", {
																						syncMsgVersion =
																						{
																						  majorVersion = 3,
																						  minorVersion = 1
																						},
																						appName = "SPTtest",
																						isMediaApplication = false,
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

			--hmi side: expect BasicCommunication.OnAppRegistered request
			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
			{
				application =
				{
					appName = "SPTtest",
					policyAppID = "1234567",
					appID = self.applications["SPTtest"]
				}
			})

			--mobile side: expect response
			self.mobileSession:ExpectResponse(CorIdRegister, {success = true, resultCode = "SUCCESS"})

			--mobile side: expect notification
			self.mobileSession:ExpectNotification("OnHMIStatus", {systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})

		end

	end

	TC_OnAppUnregistered_01()



---------------------------------------------------------------------------------------------
--SDLAQ-TC-424: TC_OnAppUnregistered_02
--APPLINK-16315: 24[P][MAN]_TC_OnAppUnregistered_after_transport_disconnected
---------------------------------------------------------------------------------------------
	local function TC_OnAppUnregistered_02()

		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup("Test case: TC_OnAppUnregistered_02, 24[P][MAN]_TC_OnAppUnregistered_after_transport_disconnected")

		--Precondition
		function Test:Unregister_Application_02()

			local cid = self.mobileSession:SendRPC("UnregisterAppInterface",{})

			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
			:Timeout(2000)
		end

		function Test:StopHeartBeat_02()
			self.mobileSession:StopHeartbeat()
		end

		function Test:Register_App_Interface_And_Store_appID_02()

			--mobile side: send RegisterAppInterface request
			local CorIdRegister = self.mobileSession:SendRPC("RegisterAppInterface", {
																						syncMsgVersion =
																						{
																						  majorVersion = 3,
																						  minorVersion = 1
																						},
																						appName = "SPTtest",
																						isMediaApplication = false,
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

			--hmi side: expect BasicCommunication.OnAppRegistered request
			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
			{
				application =
				{
					appName = "SPTtest",
					policyAppID = "1234567"
				}
			})
			:Do(function(_,data)
				self.applications["SPTtest"] = data.params.application.appID
			end)

			--mobile side: expect response
			self.mobileSession:ExpectResponse(CorIdRegister, {success = true})

			--mobile side: expect notification
			self.mobileSession:ExpectNotification("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})

		end

		function Test:MobileCloseConnection_Verify_OnAppUnregistered_02()

			--mobile side: close connection
			self.mobileConnection:Close()

			--hmi side: expect BasicCommunication.OnAppUnregistered
			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.applications["SPTtest"], unexpectedDisconnect =  true})

		end

		function Test:ConnectMobileAgain_02()
		  self:connectMobile()
		end

		function Test:StartSession_02()
		  --self:startSession_WithoutRegisterApp()
		  startSession(self)
		end

		function Test:Register_App_Interface_Again_And_Verify_appID_Is_Not_Changed_02()


			local CorIdRegister = self.mobileSession:SendRPC("RegisterAppInterface", {
																						syncMsgVersion =
																						{
																						  majorVersion = 3,
																						  minorVersion = 1
																						},
																						appName = "SPTtest",
																						isMediaApplication = false,
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

			--hmi side: expect BasicCommunication.OnAppRegistered request
			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
			{
				application =
				{
					appName = "SPTtest",
					policyAppID = "1234567",
					appID = self.applications["SPTtest"]
				}
			})

			--mobile side: expect response
			self.mobileSession:ExpectResponse(CorIdRegister, {success = true, resultCode = "SUCCESS"})

			--mobile side: expect notification
			self.mobileSession:ExpectNotification("OnHMIStatus", {systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})

		end


	end

	TC_OnAppUnregistered_02()



---------------------------------------------------------------------------------------------
--SDLAQ-TC-429: TC_OnAppUnregistered_05
--APPLINK-18356: 25[P][MAN]_TC_OnAppUnregistered_if_appName_doesn't_match_nickname_in_PT
---------------------------------------------------------------------------------------------
	local function TC_OnAppUnregistered_05()
		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup("Test case: TC_OnAppUnregistered_05, 25[P][MAN]_TC_OnAppUnregistered_if_appName_doesn't_match_nickname_in_PT")

		--Preconditions: Stop SDL, start SDL again, start HMI, connect to SDL, start mobile, start new session.
		StopSDL_StartSDL_InitHMI_ConnectMobile("05_precondition")
		---------------------------------------------------------------------------------------------

		function Test:Register_App_Interface_05()


			local CorIdRegister = self.mobileSession:SendRPC("RegisterAppInterface", {
																						syncMsgVersion =
																						{
																						  majorVersion = 3,
																						  minorVersion = 1
																						},
																						appName = "SPTtest",
																						isMediaApplication = false,
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

			--hmi side: expect BasicCommunication.OnAppRegistered request
			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
			{
				application =
				{
					appName = "SPTtest"
				}
			})
			:Do(function(_,data)
				self.applications["SPTtest"] = data.params.application.appID
			end)

			--mobile side: expect response
			self.mobileSession:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS"})

			--mobile side: expect notification
			self.mobileSession:ExpectNotification("OnHMIStatus",
			{
				systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"
			})

		end

		function Test:Activation_App_05()

			local Input_AppId = self.applications["SPTtest"]

			--hmi side: sending SDL.ActivateApp request
			local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = Input_AppId})
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

		function Test:UpdatePolicyFromMobile_APP_UNAUTHORIZED_05()

			--mobile side: sending SystemRequest request
			local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
																					{
																						fileName = "PolicyTableUpdate",
																						requestType = "HTTP"
																					},
																					"files/PTU_ForOnAppUnregistered_05.json")


			--hmi side: expect SystemRequest request
			EXPECT_HMICALL("BasicCommunication.SystemRequest", {requestType = "HTTP",  fileName = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate"})
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
			EXPECT_HMINOTIFICATION("SDL.OnAppPermissionChanged", {appID = self.applications["SPTtest"], appUnauthorized =  true, priority = "NORMAL"})
			:Do(function(_,data)

				--hmi side: sending SDL.GetUserFriendlyMessage request to SDL
				local RequestIdGetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"AppUnauthorized"}})

				--hmi side: expect SDL.GetUserFriendlyMessage response
				EXPECT_HMIRESPONSE(RequestIdGetUserFriendlyMessage,{result = {code = 0, method = "SDL.GetUserFriendlyMessage", messages = {{
													line1 = "Not Authorized",
													messageCode = "AppUnauthorized",
													textBody = "This version of %appName% is no longer authorized to work with Mobile Apps. Please update to the latest version of %appName%.",
													ttsString = "This version of %appName% is not authorized and will not work with SYNC."}}}})
			end)


			--hmi side: expect BasicCommunication.OnAppUnregistered
			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.applications["SPTtest"], unexpectedDisconnect =  false})


			--mobile side: expect notification
			self.mobileSession:ExpectNotification("OnAppInterfaceUnregistered", {reason = "APP_UNAUTHORIZED"})


			 EXPECT_HMICALL("BasicCommunication.UpdateAppList")
			:Do(function(_, data)
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
			end)
			:ValidIf (function(_,data)
				for _, app in pairs(data.params.applications) do
					if app.appID == self.applications["SPTtest"] then
						commonFunctions:printError(" Application is not removed on AppsList ")
						return false
					end
				end

				return true

			end)

			--mobile side: expect response
			self.mobileSession:ExpectResponse(CorIdSystemRequest, {success = true, resultCode = "SUCCESS"})
		end

	end

	--TODO: For now TC_OnAppUnregistered_05 ( covering of 25[P][MAN]_TC_OnAppUnregistered_if_appName_doesn't_match_nickname_in_PT(APPLINK-18356)) is blocked by ATF defect APPLINK-19188
	--TC_OnAppUnregistered_05()


---------------------------------------------------------------------------------------------
--SDLAQ-TC-430: TC_OnAppUnregistered_06
--APPLINK-18357: 26[P][MAN]_TC_OnAppUnregistered_if_IGNOF/MASTER_RESET/FACTORY_DEFAULTS
---------------------------------------------------------------------------------------------
	local function TC_OnAppUnregistered_06()
		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup("Test case: TC_OnAppUnregistered_06, 26[P][MAN]_TC_OnAppUnregistered_if_IGNOF/MASTER_RESET/FACTORY_DEFAULTS")


		local function Register_App_Interface(TestCaseName)

			Test[TestCaseName] = function(self)


				local CorIdRegister = self.mobileSession:SendRPC("RegisterAppInterface", {
																							syncMsgVersion =
																							{
																							  majorVersion = 3,
																							  minorVersion = 1
																							},
																							appName = "SPT_05",
																							isMediaApplication = false,
																							languageDesired = 'EN-US',
																							hmiDisplayLanguageDesired = 'EN-US',
																							appHMIType = { "DEFAULT" },
																							appID = "1234567_05",
																							deviceInfo =
																							{
																							  os = "Android",
																							  carrier = "Megafon",
																							  firmwareRev = "Name: Linux, Version: 3.4.0-perf",
																							  osVersion = "4.4.2",
																							  maxNumberRFCOMMPorts = 1
																							}
																						  })

				--hmi side: expect BasicCommunication.OnAppRegistered request
				EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
				{
					application =
					{
						appName = "SPT_05"
					}
				})
				:Do(function(_,data)
					self.applications["SPT_05"] = data.params.application.appID
				end)

				--mobile side: expect response
				self.mobileSession:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS"})

				--mobile side: expect notification
				self.mobileSession:ExpectNotification("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})

			end

		end

		--Preconditions: Stop SDL, start SDL again, start HMI, connect to SDL, start mobile, start new session.
		StopSDL_StartSDL_InitHMI_ConnectMobile("06_1_precondition")

		Register_App_Interface("Register_App_Interface_06_1")

		function Test:OnAppUnregistered_IGNITION_OFF_06()

			--hmi side: sending BasicCommunication.OnSystemRequest request to SDL
			self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", {reason = "IGNITION_OFF"})

			--hmi side: expect BasicCommunication.OnAppUnregistered
			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.applications["SPT_05"], unexpectedDisconnect =  false})

			--mobile side: expect notification
			self.mobileSession:ExpectNotification("OnAppInterfaceUnregistered", {reason = "IGNITION_OFF"})

		end

		--Postconditions: Stop SDL, start SDL again, start HMI, connect to SDL, start mobile, start new session.
		StopSDL_StartSDL_InitHMI_ConnectMobile("06_1_postcondition")
		---------------------------------------------------------------------------------------------

		Register_App_Interface("Register_App_Interface_06_2")

		function Test:OnAppUnregistered_FACTORY_DEFAULTS_06()

			--hmi side: sending BasicCommunication.OnSystemRequest request to SDL
			self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", {reason = "FACTORY_DEFAULTS"})

			--hmi side: expect BasicCommunication.OnAppUnregistered
			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.applications["SPT_05"], unexpectedDisconnect =  false})

			--mobile side: expect notification
			self.mobileSession:ExpectNotification("OnAppInterfaceUnregistered", {reason = "FACTORY_DEFAULTS"})

		end


		--Postconditions: Stop SDL, start SDL again, start HMI, connect to SDL, start mobile, start new session.
		StopSDL_StartSDL_InitHMI_ConnectMobile("06_2_postcondition")
		---------------------------------------------------------------------------------------------

		Register_App_Interface("Register_App_Interface_06_3")

		function Test:OnAppUnregistered_MASTER_RESET_06()

			--hmi side: sending BasicCommunication.OnSystemRequest request to SDL
			self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", {reason = "MASTER_RESET"})

			--hmi side: expect BasicCommunication.OnAppUnregistered
			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.applications["SPT_05"], unexpectedDisconnect =  false})

			--mobile side: expect notification
			self.mobileSession:ExpectNotification("OnAppInterfaceUnregistered", {reason = "MASTER_RESET"})

		end
		---------------------------------------------------------------------------------------------



	end

	TC_OnAppUnregistered_06()

---------------------------------------------------------------------------------------------
-------------------------------------------Postcondition-------------------------------------
---------------------------------------------------------------------------------------------

	--Print new line to separate Postconditions
	commonFunctions:newTestCasesGroup("Postconditions")

	function Test:Postcondition_StopSDL_IfItIsExist()
	  StopSDL()
	end

	--Restore sdl_preloaded_pt.json
	policyTable:Restore_preloaded_pt()



 return Test


