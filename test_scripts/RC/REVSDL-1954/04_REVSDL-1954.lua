local commonSteps = require("user_modules/shared_testcases/commonSteps")
commonSteps:CheckSDLPath()
commonSteps:DeleteLogsFileAndPolicyTable()

local commonPreconditions = require("user_modules/shared_testcases/commonPreconditions")
commonPreconditions:BackupFile("sdl_preloaded_pt.json")
commonPreconditions:ReplaceFile("sdl_preloaded_pt.json", "./files/jsons/RC/rc_sdl_preloaded_pt.json")

local revsdl = require("user_modules/revsdl")

revsdl.AddUnknownFunctionIDs()
revsdl.SubscribeToRcInterface()
config.ValidateSchema = false
config.application1.registerAppInterfaceParams.appHMIType = { "REMOTE_CONTROL" }
config.application1.registerAppInterfaceParams.appID = "8675311"

Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local mobile  = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')
local config = require('config')


---------------------------------------------------------------------------------------------
--Declaration connected devices.
--1. Device 2:
local device2 = "192.168.100.199"
local device2Port = 12345
--2. Device 3:
local device3 = "10.42.0.1"
local device3Port = 12345

local device1mac = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

os.execute("ifconfig lo:1 192.168.100.199")
os.execute("ifconfig lo:2 10.42.0.1")

---------------------------------------------------------------------------------------------
--ID for app that duplicates name
local ID

--List permission of "OnPermissionsChange" for PrimaryDevice and NonPrimaryDevice
--groups_PrimaryRC Group
local arrayGroups_PrimaryRC = revsdl.arrayGroups_PrimaryRC()

---------------------------------------------------------------------------------------------
-------------------------------------STARTING COMMON FUNCTIONS-------------------------------
---------------------------------------------------------------------------------------------

--Using for timeout
function sleep(iTimeout)
 os.execute("sleep "..tonumber(iTimeout))
end
--Using for delaying event when AppRegistration
function DelayedExp()
  local event = events.Event()
  event.matches = function(self, e) return self == e end
  EXPECT_EVENT(event, "Delayed event")
  RUN_AFTER(function()
              RAISE_EVENT(event, event)
            end, 2000)
end

--New connection device2
function newConnectionDevice2(self, DeviceIP, Port)

  local tcpConnection = tcp.Connection(DeviceIP, Port)
  local fileConnection = file_connection.FileConnection("mobile2.out", tcpConnection)
  self.mobileConnection2 = mobile.MobileConnection(fileConnection)
  self.mobileSession21 = mobile_session.MobileSession(
		self,
		self.mobileConnection2,
		config.application1.registerAppInterfaceParams
	)
  event_dispatcher:AddConnection(self.mobileConnection2)
  self.mobileSession21:ExpectEvent(events.connectedEvent, "Connection started")
  self.mobileConnection2:Connect()
end

--New connection device3
function newConnectionDevice3(self, DeviceIP1, Port)

  local tcpConnection = tcp.Connection(DeviceIP1, Port)
  local fileConnection = file_connection.FileConnection("mobile3.out", tcpConnection)
  self.mobileConnection3 = mobile.MobileConnection(fileConnection)
  self.mobileSession31 = mobile_session.MobileSession(
		self,
		self.mobileConnection3,
		config.application1.registerAppInterfaceParams
	)
  event_dispatcher:AddConnection(self.mobileConnection3)
  self.mobileSession31:ExpectEvent(events.connectedEvent, "Connection started")
  self.mobileConnection3:Connect()
end

---------------------------------------------------------------------------------------------
----------------------------------------END COMMON FUNCTIONS---------------------------------
---------------------------------------------------------------------------------------------



--======================================Requirement========================================--
---------------------------------------------------------------------------------------------
-----------Requirement: Same-named applications with the same appIDs must be-----------------
--------------------------------allowed from different devices-------------------------------
---------------------------------------------------------------------------------------------
--=========================================================================================--

--=================================================BEGIN TEST CASES 4==========================================================--
	--Begin Test suit CommonRequestCheck.4 for Req.#4

	--Description: 4. In case In case a REMOTE_CONTROL application with <appName> and <appID> is registered with SDL from driver's device
							-- and another REMOTE_CONTROL application with the same <appName> and the different <appID> from the same or another driver's device requests registration via a separate session
							-- RSDL must respond with RegisterAppInterface (resultCode: DUPLICATE_NAME, success: false, params)

	--Begin Test case CommonRequestCheck.4.1
	--Description: 	In case In case a REMOTE_CONTROL application with <appName> and <appID> is registered with SDL from driver's device
					--Same <deviceRank>: Setting Driver's device before App1 Connected

		--Requirement/Diagrams id in jira:
				--Requirement

		--Verification criteria:
				--RSDL must respond with RegisterAppInterface (resultCode: DUPLICATE_NAME, success: false, params)

			--Begin Test case Precondition.1.1.1
			--Description: Register new session for register new apps
			function Test:TC4_NewApps()

			self.mobileSession11 = mobile_session.MobileSession(
				self,
				self.mobileConnection)

			self.mobileSession12 = mobile_session.MobileSession(
				self,
				self.mobileConnection)

			end
			--End Test case Precondition.1.1.1

		-----------------------------------------------------------------------------------------

			--Begin Test case Precondition.1.1.2
			--Description: Set Device1 to Driver's device
			   function Test:TC4_SetDevice1ToDriver()

					--hmi side: send request RC.OnDeviceRankChanged
					self.hmiConnection:SendNotification("RC.OnDeviceRankChanged",
															{deviceRank = "DRIVER", device = {name = "127.0.0.1", id = device1mac, isSDLAllowed = true}})

					--mobile side: Expect OnPermissionsChange notification for Driver's device
					self.mobileSession:ExpectNotification("OnPermissionsChange", arrayGroups_PrimaryRC )

					--mobile side: OnHMIStatus notifications with deviceRank = "DRIVER"
					--self.mobileSession:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "DRIVER" })

				end
			--End Test case Precondition.1.1.2

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.4.1.3
			--Description: Register App1 from Device1
			   function Test:TC4_App1FromDevice1()

				--mobile side: RegisterAppInterface request
				  self.mobileSession11:StartService(7)
				  :Do(function()
				   local CorIdRAI = self.mobileSession11:SendRPC("RegisterAppInterface",
						   {

							syncMsgVersion =
							{
							 majorVersion = 2,
							 minorVersion = 2,
							},
							appName ="App1",
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
							isMediaApplication = true,
							languageDesired ="EN-US",
							hmiDisplayLanguageDesired ="EN-US",
							appHMIType = { "NAVIGATION", "REMOTE_CONTROL" },
							appID ="1",

						   })

					EXPECT_HMICALL("BasicCommunication.OnAppRegistered",
					{
					  application =
					  {
						appName = "App1"
					  }
					})
					:Do(function(_,data)
						self.applications["App1"] = data.params.application.appID
					end)


				   --mobile side: RegisterAppInterface response
				   self.mobileSession11:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"},
						{

							syncMsgVersion =
							{
							 majorVersion = 2,
							 minorVersion = 2,
							},
							appName ="App1",
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
							isMediaApplication = true,
							languageDesired ="EN-US",
							hmiDisplayLanguageDesired ="EN-US",
							appHMIType = { "NAVIGATION", "REMOTE_CONTROL" },
							appID ="1",

						}
				   )

					--mobile side: Expect OnPermissionsChange notification for DRIVER's device
					self.mobileSession11:ExpectNotification("OnPermissionsChange", arrayGroups_PrimaryRC )

				  end)

			   end
			--End Test case CommonRequestCheck.4.1.3

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.4.1.4
			--Description: Register App2 with the same <appName> and different <appID> from a passenger device1
			   function Test:TC4_App2FromDevice1()

				--mobile side: RegisterAppInterface request
				  self.mobileSession12:StartService(7)
				  :Do(function()
				   local CorIdRAI = self.mobileSession12:SendRPC("RegisterAppInterface",
						{

							syncMsgVersion =
							{
							 majorVersion = 2,
							 minorVersion = 2,
							},
							appName ="App1",
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
							isMediaApplication = true,
							languageDesired ="EN-US",
							hmiDisplayLanguageDesired ="EN-US",
							appHMIType = { "NAVIGATION", "REMOTE_CONTROL" },
							appID ="2",

						})

					EXPECT_HMICALL("BasicCommunication.OnAppRegistered",
					{
					  application =
					  {
						appName = "App1"
					  }
					})
					:Times(0)
					:Do(function(_,data)
						self.applications["App1"] = data.params.application.appID
					end)


				   --mobile side: RegisterAppInterface response
				   self.mobileSession12:ExpectResponse(CorIdRAI, { success = false, resultCode = "DUPLICATE_NAME"},
						{

							syncMsgVersion =
							{
							 majorVersion = 2,
							 minorVersion = 2,
							},
							appName ="App1",
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
							isMediaApplication = true,
							languageDesired ="EN-US",
							hmiDisplayLanguageDesired ="EN-US",
							appHMIType = { "NAVIGATION", "REMOTE_CONTROL" },
							appID ="2",

						})

				  end)

			   end
			--End Test case CommonRequestCheck.4.1.4

		-----------------------------------------------------------------------------------------
	--End Test case CommonRequestCheck.4.1

--=================================================END TEST CASES 4==========================================================--

function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end