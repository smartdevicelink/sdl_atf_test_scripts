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

--List permission of "OnPermissionsChange" for PrimaryDevice and NonPrimaryDevice
--NonPrimaryNotification Group
local arrayGroups_nonPrimaryRCNotification = revsdl.arrayGroups_nonPrimaryRCNotification()


--======================================Requirement========================================--
---------------------------------------------------------------------------------------------
-----------Requirement: Subscriptions: reset upon device rank change and RC disabling--------
---------------------------------------------------------------------------------------------
--=========================================================================================--

--=================================================BEGIN TEST CASES 3==========================================================--
	--Begin Test suit CommonRequestCheck.3 for Req.#3

	--Description: 3. In case RC app from passenger's <deviceID> device is subscribed to InteriorVehicleData notifications in <module+zone> and RSDL gets RC.OnReverseAppsAllowing (allowed: false) from HMI
						-- RSDL must
						-- 3.1. internally unsubscribe this app
						-- 3.2. send RC.GetInteriorVehicleData ("subscribe:false", <module+zone>) to HMI.

	--Begin Test case CommonRequestCheck.3.1
	--Description: 	In case RC app from passenger's <deviceID> device is subscribed to InteriorVehicleData notifications in <module+zone> and RSDL gets RC.OnReverseAppsAllowing (allowed: false) from HMI

		--Requirement/Diagrams id in jira:
				--Requirement
				--Diagram(See opt.#3): https://adc.luxoft.com/jira/secure/attachment/128872/128872_Model_subscriptions-taking-off.png

		--Verification criteria:
				--In case RC app from passenger's <deviceID> device is subscribed to InteriorVehicleData notifications in <module+zone> and RSDL gets RC.OnReverseAppsAllowing (allowed: false) from HMI

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.1.1
			--Description: --1. Application sends GetInteriorVehicleData as Zone = Driver and ModuleType = CLIMATE
						   --2. HMI sends OnInteriorVehicleData notification to RSDL
				function Test:TC1_Pre_PassengerDriverCLIMATE()
					--mobile sends request for precondition as Driver
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleData",
					{
						moduleDescription =
						{
							moduleType = "CLIMATE",
							moduleZone =
							{
								colspan = 2,
								row = 0,
								rowspan = 2,
								col = 0,
								levelspan = 1,
								level = 0,
							}
						},
						subscribe = true
					})

					--hmi side: expect RC.GetInteriorVehicleData request
					EXPECT_HMICALL("RC.GetInteriorVehicleData")
					:Do(function(_,data)
						--hmi side: sending GetInteriorVehicleData_response (<module+zone>, "isSubscribed:true", resultCode:SUCCESS)
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { isSubscribed = true,
							moduleData =
							{
								moduleType = "CLIMATE",
								moduleZone =
								{
									colspan = 2,
									row = 0,
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
									row = 0,
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



					--mobile side: expect SUCCESS response with info
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", isSubscribed = true})

					--mobile side: RSDL sends notifications to mobile app
					EXPECT_NOTIFICATION("OnInteriorVehicleData")
					:Times(1)

				end
			--End Test case CommonRequestCheck.3.1.1

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.1.2
			--Description: --1. Application sends GetInteriorVehicleData as Zone = Front Passenger and ModuleType = CLIMATE
						   --2. HMI sends OnInteriorVehicleData notification to RSDL
				function Test:TC1_Pre_PassengerFrontCLIMATE()
					--mobile sends request for precondition as Front Passenger
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleData",
					{
						moduleDescription =
						{
							moduleType = "CLIMATE",
							moduleZone =
							{
								colspan = 2,
								row = 0,
								rowspan = 2,
								col = 1,
								levelspan = 1,
								level = 0,
							}
						},
						subscribe = true
					})

					--hmi side: expect RC.GetInteriorVehicleData request
					EXPECT_HMICALL("RC.GetInteriorVehicleData")
						:Do(function(_,data)
							--hmi side: sending GetInteriorVehicleData_response (<module+zone>, "isSubscribed:true", resultCode:SUCCESS)
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { isSubscribed = true,
								moduleData =
								{
									moduleType = "CLIMATE",
									moduleZone =
									{
										colspan = 2,
										row = 0,
										rowspan = 2,
										col = 1,
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
										row = 0,
										rowspan = 2,
										col = 1,
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



					--mobile side: expect SUCCESS response with info
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", isSubscribed = true})

					--mobile side: RSDL sends notifications to mobile app
					EXPECT_NOTIFICATION("OnInteriorVehicleData")
					:Times(1)

				end
			--End Test case CommonRequestCheck.3.1.2

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.1.3
			--Description: --1. Application sends GetInteriorVehicleData as Zone = Left Rare Passenger and ModuleType = CLIMATE
						   --2. HMI sends OnInteriorVehicleData notification to RSDL
				function Test:TC1_Pre_PassengerLeftCLIMATE()
					--mobile side: --mobile sends request for precondition as Left Rare Passenger
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleData",
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
									appID = self.applications["Test Application"],
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
									--hmi side: sending GetInteriorVehicleData_response (<module+zone>, "isSubscribed:true", resultCode:SUCCESS)
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
												fanSpeed = 50,
												circulateAirEnable = false,
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



					--mobile side: expect SUCCESS response with info
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", isSubscribed = true})

					--mobile side: RSDL sends notifications to mobile app
					EXPECT_NOTIFICATION("OnInteriorVehicleData")
					:Times(1)

				end
			--End Test case CommonRequestCheck.3.1.3

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.1.4
			--Description: --1. Application sends GetInteriorVehicleData as Zone = Driver and ModuleType = RADIO
						   --2. HMI sends OnInteriorVehicleData notification to RSDL
				function Test:TC1_Pre_PassengerDriverRADIO()
					--mobile sends request for precondition as Driver
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleData",
					{
						moduleDescription =
						{
							moduleType = "RADIO",
							moduleZone =
							{
								colspan = 2,
								row = 0,
								rowspan = 2,
								col = 0,
								levelspan = 1,
								level = 0,
							}
						},
						subscribe = true
					})

					--hmi side: expect RC.GetInteriorVehicleData request
					EXPECT_HMICALL("RC.GetInteriorVehicleData")
						:Do(function(_,data)
							--hmi side: sending GetInteriorVehicleData_response (<module+zone>, "isSubscribed:true", resultCode:SUCCESS)
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { isSubscribed = true,
								moduleData = {
									moduleType = "RADIO",
									moduleZone = {
										col = 0,
										colspan = 2,
										level = 0,
										levelspan = 1,
										row = 0,
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
										row = 0,
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



					--mobile side: expect SUCCESS response with info
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", isSubscribed = true})

					--mobile side: RSDL sends notifications to mobile app
					EXPECT_NOTIFICATION("OnInteriorVehicleData")
					:Times(1)

				end
			--End Test case CommonRequestCheck.3.1.4

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.1.5
			--Description: --1. Application sends GetInteriorVehicleData as Zone = Front Passenger and ModuleType = RADIO
						   --2. HMI sends OnInteriorVehicleData notification to RSDL
				function Test:TC1_Pre_PassengerFrontRADIO()
					--mobile sends request for precondition as Front Passenger
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleData",
					{
						moduleDescription =
						{
							moduleType = "RADIO",
							moduleZone =
							{
								colspan = 2,
								row = 0,
								rowspan = 2,
								col = 1,
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
										row = 0,
										rowspan = 2,
										col = 1,
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
									--hmi side: sending GetInteriorVehicleData_response (<module+zone>, "isSubscribed:true", resultCode:SUCCESS)
									self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { isSubscribed = true,
										moduleData = {
											moduleType = "RADIO",
											moduleZone = {
												col = 1,
												colspan = 2,
												level = 0,
												levelspan = 1,
												row = 0,
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
												col = 1,
												colspan = 2,
												level = 0,
												levelspan = 1,
												row = 0,
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


					--mobile side: expect SUCCESS response with info
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", isSubscribed = true})

					--mobile side: RSDL sends notifications to mobile app
					EXPECT_NOTIFICATION("OnInteriorVehicleData")
					:Times(1)

				end
			--End Test case CommonRequestCheck.3.1.5

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.1.6
			--Description: --1. Application sends GetInteriorVehicleData as Zone = Left Rare Passenger and ModuleType = RADIO
						   --2. HMI sends OnInteriorVehicleData notification to RSDL
				function Test:TC1_Pre_PassengerLeftRADIO()
					--mobile sends request for precondition as Left Rare Passenger
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
									--hmi side: sending GetInteriorVehicleData_response (<module+zone>, "isSubscribed:true", resultCode:SUCCESS)
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


					--mobile side: expect SUCCESS response with info
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", isSubscribed = true})

					--mobile side: RSDL sends notifications to mobile app
					EXPECT_NOTIFICATION("OnInteriorVehicleData")
					:Times(1)

				end
			--End Test case CommonRequestCheck.3.1.6

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.1.7
			--Description: --Disable RemoteControl from passenger's device and checking Unsubscribed
				function Test:CheckUnsubscribedDisableRC()

					--hmi side: Send valid RC.OnReverseAppsAllowing (allowed: false) from emulation HMI.
					self.hmiConnection:SendNotification("VehicleInfo.OnReverseAppsAllowing", {allowed = false})

					--mobile side: mobile receives notification
					EXPECT_NOTIFICATION("OnPermissionsChange", arrayGroups_nonPrimaryRCNotification)

					--RSDL -> HMI: RC.GetInteriorVehicleData ("subscribe:false", <module+zone>).
					EXPECT_HMICALL("RC.GetInteriorVehicleData",
					{
							appID = self.applications["Test Application"],
							moduleDescription = {
								moduleType = "CLIMATE",
								moduleZone =
								{
									colspan = 2,
									row = 0,
									rowspan = 2,
									col = 0,
									levelspan = 1,
									level = 0,
								}
							},
							subscribe = false
						},
						{
							appID = self.applications["Test Application"],
							moduleDescription = {
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
							subscribe = false
						},
						{
							appID = self.applications["Test Application"],
							moduleDescription = {
								moduleType = "CLIMATE",
								moduleZone =
								{
									colspan = 2,
									row = 0,
									rowspan = 2,
									col = 1,
									levelspan = 1,
									level = 0,
								}
							},
							subscribe = false
						},
						{
							appID = self.applications["Test Application"],
							moduleDescription = {
								moduleType = "RADIO",
								moduleZone =
								{
									colspan = 2,
									row = 0,
									rowspan = 2,
									col = 0,
									levelspan = 1,
									level = 0,
								}
							},
							subscribe = false
						},
						{
							appID = self.applications["Test Application"],
							moduleDescription = {
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
							subscribe = false
						},
						{
							appID = self.applications["Test Application"],
							moduleDescription = {
								moduleType = "RADIO",
								moduleZone =
								{
									colspan = 2,
									row = 0,
									rowspan = 2,
									col = 1,
									levelspan = 1,
									level = 0,
								}
							},
							subscribe = false
						}
					)
					:Times(6)
					:Do(function(_,data)
						--Send RC.OnInteriorVehicleData (<module+zone>) from emulation HMI.

						--hmi side: HMI sends OnInteriorVehicleData notification to RSDL
						self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
							moduleData =
							{
								moduleType = "CLIMATE",
								moduleZone =
								{
									colspan = 2,
									row = 0,
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


						--hmi side: sending GetInteriorVehicleData_response (<module+zone>, "isSubscribed:true", resultCode:SUCCESS)
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { isSubscribed = true,
								moduleData =
								{
									moduleType = "CLIMATE",
									moduleZone =
									{
										colspan = 2,
										row = 0,
										rowspan = 2,
										col = 1,
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
									fanSpeed = 50,
									circulateAirEnable = false,
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
							moduleData = {
								moduleType = "RADIO",
								moduleZone = {
									col = 0,
									colspan = 2,
									level = 0,
									levelspan = 1,
									row = 0,
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

						--hmi side: HMI sends OnInteriorVehicleData notification to RSDL
						self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
							moduleData = {
								moduleType = "RADIO",
								moduleZone = {
									col = 1,
									colspan = 2,
									level = 0,
									levelspan = 1,
									row = 0,
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

					--mobile side: App is unsubscribed and does not receive notification.
					EXPECT_NOTIFICATION("OnInteriorVehicleData")
					:Times(0)

				end
			--End Test case CommonRequestCheck.3.1.7

		-----------------------------------------------------------------------------------------

	--End Test case CommonRequestCheck.3.1


--=================================================END TEST CASES 3==========================================================--

function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end