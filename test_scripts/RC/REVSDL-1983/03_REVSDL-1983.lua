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

local mobile_session = require('mobile_session')

--List permission of "OnPermissionsChange" for PrimaryDevice and NonPrimaryDevice
--groups_nonPrimaryRC Group
local arrayGroups_nonPrimaryRC = revsdl.arrayGroups_nonPrimaryRC()

--=================================================BEGIN TEST CASES 3==========================================================--
	--Begin Test suit CommonRequestCheck.3 for Requirement and Requirement

	--Description: 3. Requirement

	--Begin Test case CommonRequestCheck.3.1
	--Description: 	Subscriptions taking off - exited app
					--1. App1 and App2 have got subscription (RADIO and CLIMATE)
					--2. USER_EXIT App1 and App2 to hmiLevel=NONE
					--3. Checking App1 and App2 don’t receive OnInteriorVihicleData
					--4. Changing hmiLevel App1 and App2 to BACKGROUND
					--5. Checking App1 and App2 still receive OnInteriorVihicleData


		--Requirement/Diagrams id in jira:
				--Requirement
				--Requirement

		--Verification criteria:
				-- Policies: Configure app-specific permission to not receive OnInteriorVehicleData notification in NONE level.

		-----------------------------------------------------------------------------------------

			--Begin Test case Precondition.3.1.1
			--Description: Register new session for register new app
				function Test:TC3_Precondition1()
				  self.mobileSession1 = mobile_session.MobileSession(
					self,
					self.mobileConnection)
				end
			--End Test case Precondition.3.1.1

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.1.2
			--Description: Register App2, App2=NONE for precondition
				function Test:TC3_RegisteredApp2()
					self.mobileSession1:StartService(7)
					:Do(function()
							local CorIdRegister = self.mobileSession1:SendRPC("RegisterAppInterface",
							{
							  syncMsgVersion =
							  {
								majorVersion = 3,
								minorVersion = 0
							  },
							  appName = "Test Application1",
							  isMediaApplication = true,
							  languageDesired = 'EN-US',
							  hmiDisplayLanguageDesired = 'EN-US',
							  appHMIType = { "NAVIGATION", "REMOTE_CONTROL" },
							  appID = "1"
							})

							EXPECT_HMICALL("BasicCommunication.OnAppRegistered",
							{
							  application =
							  {
								appName = "Test Application1"
							  }
							})
							:Do(function(_,data)
								self.applications["Test Application1"] = data.params.application.appID

								--RSDL sends BC.ActivateApp (level: NONE) to HMI.
								EXPECT_HMICALL("BasicCommunication.ActivateApp",
								{
								  appID = self.applications["Test Application1"],
								  level = "NONE",
								  priority = "NONE"
								})

							end)

							--SDL sends RegisterAppInterface_response (success:true) with the following resultCodes: SUCCESS
							self.mobileSession1:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS" })

							--mobile side: Expect OnPermissionsChange notification for DRIVER's device
							self.mobileSession1:ExpectNotification("OnPermissionsChange", arrayGroups_nonPrimaryRC )

							--mobile side:RSDL sends OnHMIStatus (NONE,params) to mobile application.
							self.mobileSession1:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "PASSENGER" })

						end)
					end
			--End Test case CommonRequestCheck.3.1.2
		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.1.3
			--Description: application sends GetInteriorVehicleData as Left Rare Passenger (col=0, row=1, level=0) and ModuleType = RADIO
				function Test:Subscription_App1LeftRADIO()
					--mobile side: In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleData",
					{
						moduleDescription =
						{
							moduleType = "RADIO",
							moduleZone =
							{
								colspan = 2,
								row = 1,
								rowspan = 2,
								col = 0,
								levelspan = 1,
								level = 0,
							}
						},
						subscribe = true
					})

					--hmi side: expect RC.GetInteriorVehicleDataConsent request from HMI
					EXPECT_HMICALL("RC.GetInteriorVehicleDataConsent",
								{
									appID = self.applications["Test Application"],
									moduleType = "RADIO",
									zone =
									{
										colspan = 2,
										row = 1,
										rowspan = 2,
										col = 0,
										levelspan = 1,
										level = 0
									}
								})
						:Do(function(_,data)
							--hmi side: sending RC.GetInteriorVehicleDataConsent response to RSDL
							self.hmiConnection:SendResponse(data.id, "RC.GetInteriorVehicleDataConsent", "SUCCESS", {allowed = true})

							--hmi side: expect RC.GetInteriorVehicleData request
							EXPECT_HMICALL("RC.GetInteriorVehicleData")
							:Do(function(_,data)
									--hmi side: sending RC.GetInteriorVehicleData response
									self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { isSubscribed = true,
											moduleData = {
												moduleType = "RADIO",
												moduleZone = {
													col = 0,
													colspan = 2,
													level = 0,
													levelspan = 1,
													row = 1,
													rowspan = 2
												},
												radioControlData = {
													frequencyInteger = 99,
													frequencyFraction = 3,
													band = "FM",
													rdsData = {
														PS = "name",
														RT = "radio",
														CT = "YYYY-MM-DDThh:mm:ss.sTZD",
														PI = "Sign",
														PTY = 1,
														TP = true,
														TA = true,
														REG = "Murica"
													},
													availableHDs = 3,
													hdChannel = 1,
													signalStrength = 50,
													signalChangeThreshold = 60,
													radioEnable = true,
													state = "ACQUIRING"
												}
											}
									})


									--hmi side: HMI sends OnInteriorVehicleData notification to RSDL
									self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
										moduleData = {
											moduleType = "RADIO",
											moduleZone = {
												col = 0,
												colspan = 2,
												level = 0,
												levelspan = 1,
												row = 1,
												rowspan = 2
											},
											radioControlData = {
												frequencyInteger = 99,
												frequencyFraction = 3,
												band = "AM",
												rdsData = {
													PS = "name",
													RT = "radio",
													CT = "YYYY-MM-DDThh:mm:ss.sTZD",
													PI = "Sign",
													PTY = 1,
													TP = true,
													TA = true,
													REG = "Murica"
												},
												availableHDs = 3,
												hdChannel = 1,
												signalStrength = 50,
												signalChangeThreshold = 60,
												radioEnable = true,
												state = "ACQUIRING"
											}
										}
									})

							end)
					end)

					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

					--mobile side: RSDL sends notifications to mobile app
					EXPECT_NOTIFICATION("OnInteriorVehicleData",
					{
						moduleData =
							{
									moduleType = "RADIO",
									moduleZone = {
										col = 0,
										colspan = 2,
										level = 0,
										levelspan = 1,
										row = 1,
										rowspan = 2
									},
									radioControlData = {
										frequencyInteger = 99,
										frequencyFraction = 3,
										band = "AM",
										rdsData = {
											PS = "name",
											RT = "radio",
											CT = "YYYY-MM-DDThh:mm:ss.sTZD",
											PI = "Sign",
											PTY = 1,
											TP = true,
											TA = true,
											REG = "Murica"
										},
										availableHDs = 3,
										hdChannel = 1,
										signalStrength = 50,
										signalChangeThreshold = 60,
										radioEnable = true,
										state = "ACQUIRING"
									}
							}
						}
					)
					:Times(1)


				end
			--End Test case CommonRequestCheck.3.1.3

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.1.4
			--Description: application sends GetInteriorVehicleData as Left Rare Passenger (col=0, row=1, level=0) and ModuleType = CLIMATE
				function Test:Subscription_App2LeftCLIMATE()
					--mobile side: In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies
					local cid = self.mobileSession1:SendRPC("GetInteriorVehicleData",
					{
						moduleDescription =
						{
							moduleType = "CLIMATE",
							moduleZone =
							{
								colspan = 2,
								row = 1,
								rowspan = 2,
								col = 0,
								levelspan = 1,
								level = 0,
							}
						},
						subscribe = true
					})

					--hmi side: expect RC.GetInteriorVehicleDataConsent request from HMI
					EXPECT_HMICALL("RC.GetInteriorVehicleDataConsent",
								{
									appID = self.applications["Test Application1"],
									moduleType = "CLIMATE",
									zone =
									{
										colspan = 2,
										row = 1,
										rowspan = 2,
										col = 0,
										levelspan = 1,
										level = 0
									}
								})
						:Do(function(_,data)
							--hmi side: sending RC.GetInteriorVehicleDataConsent response to RSDL
							self.hmiConnection:SendResponse(data.id, "RC.GetInteriorVehicleDataConsent", "SUCCESS", {allowed = true})

							--hmi side: expect RC.GetInteriorVehicleData request
							EXPECT_HMICALL("RC.GetInteriorVehicleData")
							:Do(function(_,data)
									--hmi side: sending RC.GetInteriorVehicleData response
									self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { isSubscribed = true,
										moduleData =
										{
											moduleType = "CLIMATE",
											moduleZone =
											{
												colspan = 2,
												row = 1,
												rowspan = 2,
												col = 0,
												levelspan = 1,
												level = 0
											},
											climateControlData =
											{
												fanSpeed = 50,
												circulateAirEnable = true,
												dualModeEnable = true,
												currentTemp = 30,
												defrostZone = "FRONT",
												acEnable = true,
												desiredTemp = 24,
												autoModeEnable = true,
												temperatureUnit = "CELSIUS"
											}
										}
									})


									--hmi side: HMI sends OnInteriorVehicleData notification to RSDL
									self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
										moduleData =
										{
											moduleType = "CLIMATE",
											moduleZone =
											{
												colspan = 2,
												row = 1,
												rowspan = 2,
												col = 0,
												levelspan = 1,
												level = 0
											},
											climateControlData =
											{
												fanSpeed = 51,
												circulateAirEnable = true,
												dualModeEnable = true,
												currentTemp = 30,
												defrostZone = "FRONT",
												acEnable = true,
												desiredTemp = 24,
												autoModeEnable = true,
												temperatureUnit = "CELSIUS"
											}
										}
									})

							end)
					end)

					self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })

					--mobile side: RSDL sends notifications to mobile app
					self.mobileSession1:ExpectNotification("OnInteriorVehicleData",
					{
						moduleData =
							{
								moduleType = "CLIMATE",
								moduleZone =
								{
									colspan = 2,
									row = 1,
									rowspan = 2,
									col = 0,
									levelspan = 1,
									level = 0
								},
								climateControlData =
								{
									fanSpeed = 51,
									circulateAirEnable = true,
									dualModeEnable = true,
									currentTemp = 30,
									defrostZone = "FRONT",
									acEnable = true,
									desiredTemp = 24,
									autoModeEnable = true,
									temperatureUnit = "CELSIUS"
								}
							}
					}
					)
					:Times(1)


				end
			--End Test case CommonRequestCheck.3.1.4

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.1.5
			--Description: From HMI trigger HMILevel to change. Press EXIT_Application button ( BC.OnExitApplication (USER_EXIT)).
				function Test:USER_EXITApp1App2_NONE()

					--hmi side: HMI send BC.OnExitApplication to Rsdl.
					self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication", {appID = self.applications["Test Application"], reason = "USER_EXIT"})
					self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication", {appID = self.applications["Test Application1"], reason = "USER_EXIT"})

					--mobile side: Check that OnHMIStatus(NONE, deviceRank:Driver) sent by RSDL and received by App1
					EXPECT_NOTIFICATION("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE" })
					self.mobileSession1:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE" })

				end
			--End Test case CommonRequestCheck.3.1.5

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.1.6
			--Description: RSDL doesn't send OnInteriorVehicleData notification to mobile app in case HMILevel=NONE
				function Test:Subscription_App1NONE()



					--hmi side: HMI sends OnInteriorVehicleData notification to RSDL
					self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
						moduleData = {
							moduleType = "RADIO",
							moduleZone = {
								col = 0,
								colspan = 2,
								level = 0,
								levelspan = 1,
								row = 1,
								rowspan = 2
							},
							radioControlData = {
								frequencyInteger = 99,
								frequencyFraction = 5,
								band = "AM",
								rdsData = {
									PS = "name",
									RT = "radio",
									CT = "YYYY-MM-DDThh:mm:ss.sTZD",
									PI = "Sign",
									PTY = 1,
									TP = true,
									TA = true,
									REG = "Murica"
								},
								availableHDs = 3,
								hdChannel = 1,
								signalStrength = 50,
								signalChangeThreshold = 60,
								radioEnable = true,
								state = "ACQUIRING"
							}
						}
					})

					--mobile side: RSDL doesn't sends notifications to mobile app
					EXPECT_NOTIFICATION("OnInteriorVehicleData",
					{
						moduleData =
							{
									moduleType = "RADIO",
									moduleZone = {
										col = 0,
										colspan = 2,
										level = 0,
										levelspan = 1,
										row = 1,
										rowspan = 2
									},
									radioControlData = {
										frequencyInteger = 99,
										frequencyFraction = 5,
										band = "AM",
										rdsData = {
											PS = "name",
											RT = "radio",
											CT = "YYYY-MM-DDThh:mm:ss.sTZD",
											PI = "Sign",
											PTY = 1,
											TP = true,
											TA = true,
											REG = "Murica"
										},
										availableHDs = 3,
										hdChannel = 1,
										signalStrength = 50,
										signalChangeThreshold = 60,
										radioEnable = true,
										state = "ACQUIRING"
									}
							}
						}
					)
					:Times(0)


				end
			--End Test case CommonRequestCheck.3.1.6

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.1.7
			--Description: RSDL doesn't send OnInteriorVehicleData notification to mobile app in case HMILevel=NONE
				function Test:Subscription_App2NONE()



					--hmi side: HMI sends OnInteriorVehicleData notification to RSDL
					self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
						moduleData =
						{
							moduleType = "CLIMATE",
							moduleZone =
							{
								colspan = 2,
								row = 1,
								rowspan = 2,
								col = 0,
								levelspan = 1,
								level = 0
							},
							climateControlData =
							{
								fanSpeed = 52,
								circulateAirEnable = true,
								dualModeEnable = true,
								currentTemp = 30,
								defrostZone = "FRONT",
								acEnable = true,
								desiredTemp = 24,
								autoModeEnable = true,
								temperatureUnit = "CELSIUS"
							}
						}
					})

					--mobile side: RSDL doesn't send notifications to mobile app
					self.mobileSession1:ExpectNotification("OnInteriorVehicleData",
					{
						moduleData =
							{
								moduleType = "CLIMATE",
								moduleZone =
								{
									colspan = 2,
									row = 1,
									rowspan = 2,
									col = 0,
									levelspan = 1,
									level = 0
								},
								climateControlData =
								{
									fanSpeed = 52,
									circulateAirEnable = true,
									dualModeEnable = true,
									currentTemp = 30,
									defrostZone = "FRONT",
									acEnable = true,
									desiredTemp = 24,
									autoModeEnable = true,
									temperatureUnit = "CELSIUS"
								}
							}
					}
					)
					:Times(0)


				end
			--End Test case CommonRequestCheck.3.1.7

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.1.8
			--Description: application sends ButtonPress to change HMI Level = BACKGROUND
				function Test:App1_HMILevel_BACKGROUND()
					local cid = self.mobileSession:SendRPC("ButtonPress",
					{
						zone =
						{
							colspan = 2,
							row = 0,
							rowspan = 2,
							col = 0,
							levelspan = 1,
							level = 0
						},
						moduleType = "RADIO",
						buttonPressMode = "LONG",
						buttonName = "VOLUME_UP"
					})

					--hmi side: expect Buttons.ButtonPress request
				EXPECT_HMICALL("Buttons.ButtonPress",
								{
									zone =
									{
										colspan = 2,
										row = 0,
										rowspan = 2,
										col = 0,
										levelspan = 1,
										level = 0
									},
									moduleType = "RADIO",
									buttonPressMode = "LONG",
									buttonName = "VOLUME_UP"
								})
					:Do(function(_,data)
						--hmi side: sending Buttons.ButtonPress response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)

					self.mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
					--mobile side:RSDL sends OnHMIStatus (BACKGROUND,params) to mobile application.
					self.mobileSession:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE"})


				end
			--End Test case CommonRequestCheck.3.1.8

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.1.9
			--Description: application sends ButtonPress to change HMI Level = BACKGROUND
				function Test:App2_HMILevel_BACKGROUND()

					local cid = self.mobileSession1:SendRPC("ButtonPress",
					{
						zone =
						{
							colspan = 2,
							row = 0,
							rowspan = 2,
							col = 0,
							levelspan = 1,
							level = 0
						},
						moduleType = "RADIO",
						buttonPressMode = "LONG",
						buttonName = "VOLUME_UP"
					})

					--hmi side: expect Buttons.ButtonPress request
					EXPECT_HMICALL("Buttons.ButtonPress",
									{
										zone =
										{
											colspan = 2,
											row = 0,
											rowspan = 2,
											col = 0,
											levelspan = 1,
											level = 0
										},
										moduleType = "RADIO",
										buttonPressMode = "LONG",
										buttonName = "VOLUME_UP"
									})
						:Do(function(_,data)
							--hmi side: sending Buttons.ButtonPress response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)

					self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
					--mobile side:RSDL sends OnHMIStatus (BACKGROUND,params) to mobile application.
					self.mobileSession1:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE"})

				end
			--End Test case CommonRequestCheck.3.1.9

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.1.10
			--Description: application sends GetInteriorVehicleData as Left Rare Passenger (col=0, row=1, level=0) and ModuleType = RADIO
				function Test:Subscription_App1BACKGROUND()



					--hmi side: HMI sends OnInteriorVehicleData notification to RSDL
					self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
						moduleData = {
							moduleType = "RADIO",
							moduleZone = {
								col = 0,
								colspan = 2,
								level = 0,
								levelspan = 1,
								row = 1,
								rowspan = 2
							},
							radioControlData = {
								frequencyInteger = 99,
								frequencyFraction = 5,
								band = "AM",
								rdsData = {
									PS = "name",
									RT = "radio",
									CT = "YYYY-MM-DDThh:mm:ss.sTZD",
									PI = "Sign",
									PTY = 1,
									TP = true,
									TA = true,
									REG = "Murica"
								},
								availableHDs = 3,
								hdChannel = 1,
								signalStrength = 50,
								signalChangeThreshold = 60,
								radioEnable = true,
								state = "ACQUIRING"
							}
						}
					})

					--mobile side: RSDL sends notifications to mobile app
					EXPECT_NOTIFICATION("OnInteriorVehicleData",
					{
						moduleData =
							{
									moduleType = "RADIO",
									moduleZone = {
										col = 0,
										colspan = 2,
										level = 0,
										levelspan = 1,
										row = 1,
										rowspan = 2
									},
									radioControlData = {
										frequencyInteger = 99,
										frequencyFraction = 5,
										band = "AM",
										rdsData = {
											PS = "name",
											RT = "radio",
											CT = "YYYY-MM-DDThh:mm:ss.sTZD",
											PI = "Sign",
											PTY = 1,
											TP = true,
											TA = true,
											REG = "Murica"
										},
										availableHDs = 3,
										hdChannel = 1,
										signalStrength = 50,
										signalChangeThreshold = 60,
										radioEnable = true,
										state = "ACQUIRING"
									}
							}
						}
					)
					:Times(1)


				end
			--End Test case CommonRequestCheck.3.1.10

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.1.11
			--Description: application sends GetInteriorVehicleData as Left Rare Passenger (col=0, row=1, level=0) and ModuleType = CLIMATE
				function Test:Subscription_App2BACKGROUND()



					--hmi side: HMI sends OnInteriorVehicleData notification to RSDL
					self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
						moduleData =
						{
							moduleType = "CLIMATE",
							moduleZone =
							{
								colspan = 2,
								row = 1,
								rowspan = 2,
								col = 0,
								levelspan = 1,
								level = 0
							},
							climateControlData =
							{
								fanSpeed = 52,
								circulateAirEnable = true,
								dualModeEnable = true,
								currentTemp = 30,
								defrostZone = "FRONT",
								acEnable = true,
								desiredTemp = 24,
								autoModeEnable = true,
								temperatureUnit = "CELSIUS"
							}
						}
					})

					--mobile side: RSDL sends notifications to mobile app
					self.mobileSession1:ExpectNotification("OnInteriorVehicleData",
					{
						moduleData =
							{
								moduleType = "CLIMATE",
								moduleZone =
								{
									colspan = 2,
									row = 1,
									rowspan = 2,
									col = 0,
									levelspan = 1,
									level = 0
								},
								climateControlData =
								{
									fanSpeed = 52,
									circulateAirEnable = true,
									dualModeEnable = true,
									currentTemp = 30,
									defrostZone = "FRONT",
									acEnable = true,
									desiredTemp = 24,
									autoModeEnable = true,
									temperatureUnit = "CELSIUS"
								}
							}
					}
					)
					:Times(1)


				end
			--End Test case CommonRequestCheck.3.1.11

		-----------------------------------------------------------------------------------------
	--End Test case CommonRequestCheck.3.1


--=================================================END TEST CASES 3==========================================================--

function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end