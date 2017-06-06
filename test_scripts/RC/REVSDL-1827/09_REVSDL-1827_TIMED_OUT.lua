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

local device1mac = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
--======================================Requirement========================================--
---------------------------------------------------------------------------------------------
--------------Requirement: Policies: "equipment" permissions must be checked-----------------
-------------------------- against location provided from HMI--------------------------------
---------------------------------------------------------------------------------------------
--=========================================================================================--




--=================================================BEGIN TEST CASES 9==========================================================--
	--Begin Test suit CommonRequestCheck.9 for Req.#9

	--Description: 9. In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies
						--and "equipment" section of policies database contains this RPC name with <params> in <moduleType> in "driver_allow" sub-section of <interiorZone> section
						--and the vehicle (HMI) responds with "disallow" for RC.GetInteriorVehicleDataConsent
						--RSDL must respond with "resultCode: USER_DISALLOWED, success: false, info: "The driver disallows this remote-control RPC" to this application.


	--Begin Test case CommonRequestCheck.9.1
	--Description: 	For ButtonPress

		--Requirement/Diagrams id in jira:
				--Requirement
				--Requirement

		--Verification criteria:
				--In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies

		-----------------------------------------------------------------------------------------
		-------------------------FOR FRONT PASSENGER ZONE----------------------------------------

			--Begin Precondition.1. HMI sends notification RC.OnDeviceLocationChanged(<deviceID>) to RSDL (zone:Front Passenger)
			--Description: HMI sends notification RC.OnDeviceLocationChanged(<deviceID>) to RSDL

				function Test:ChangedLocation_Front()
					--hmi side: HMI sends notification RC.OnDeviceLocationChanged(<deviceID>) to RSDL
					self.hmiConnection:SendNotification("RC.OnDeviceLocationChanged",
						{device = {name = "127.0.0.1", id = device1mac, isSDLAllowed = true},
							deviceLocation =
								{
									colspan = 2,
									row = 0,
									rowspan = 2,
									col = 1,
									levelspan = 1,
									level = 0
								}
						})
				end
			--End Precondition.1

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.9.1.1
			--Description: application sends ButtonPress as Driver Passenger and ModuleType = RADIO
				function Test:ButtonPress_DriverRADIO()
					--mobile side: In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies
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

					--hmi side: expect RSDL sends RC.GetInteriorVehicleDataConsent request to HMI
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
							local function HMIResponse()
								--hmi side: sending RC.GetInteriorVehicleDataConsent response to RSDL
								self.hmiConnection:SendResponse(data.id, "RC.GetInteriorVehicleDataConsent", "TIMED_OUT", {})

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
								:Times(0)
								:Do(function(_,data)
									--hmi side: sending Buttons.ButtonPress response
									self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
								end)
							end

							RUN_AFTER(HMIResponse, 10000)
					end)

					--RSDL must respond with "resultCode: USER_DISALLOWED, success: false, info: "The driver disallows this remote-control RPC" to this application.
					EXPECT_RESPONSE(cid, { success = false, resultCode = "USER_DISALLOWED", info = "The driver disallows this remote-control RPC" })
					:Timeout(11000)
				end
			--End Test case CommonRequestCheck.9.1.1

		-----------------------------------------------------------------------------------------
		-------------------------FOR LEFT PASSENGER ZONE----------------------------------------

			--Begin Precondition.1. HMI sends notification RC.OnDeviceLocationChanged(<deviceID>) to RSDL (zone:Left Passenger)
			--Description: HMI sends notification RC.OnDeviceLocationChanged(<deviceID>) to RSDL

				function Test:ChangedLocation_Left()
					--hmi side: HMI sends notification RC.OnDeviceLocationChanged(<deviceID>) to RSDL
					self.hmiConnection:SendNotification("RC.OnDeviceLocationChanged",
						{device = {name = "127.0.0.1", id = device1mac, isSDLAllowed = true},
							deviceLocation =
								{
									colspan = 2,
									row = 1,
									rowspan = 2,
									col = 0,
									levelspan = 1,
									level = 0
								}
						})
				end
			--End Precondition.1

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.9.1.2
			--Description: application sends ButtonPress as Back Right and ModuleType = CLIMATE
				function Test:ButtonPress_RightCLIMATE()
					--mobile side: In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies
					local cid = self.mobileSession:SendRPC("ButtonPress",
					{
						zone =
						{
							colspan = 2,
							row = 1,
							rowspan = 2,
							col = 1,
							levelspan = 1,
							level = 0
						},
						moduleType = "CLIMATE",
						buttonPressMode = "SHORT",
						buttonName = "LOWER_VENT"
					})

					--hmi side: expect RSDL sends RC.GetInteriorVehicleDataConsent request to HMI
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
							local function HMIResponse()
									--hmi side: sending RC.GetInteriorVehicleDataConsent response to RSDL
									self.hmiConnection:SendResponse(data.id, "RC.GetInteriorVehicleDataConsent", "TIMED_OUT", {})

									--hmi side: expect Buttons.ButtonPress request
									EXPECT_HMICALL("Buttons.ButtonPress",
													{
														zone =
														{
															colspan = 2,
															row = 1,
															rowspan = 2,
															col = 1,
															levelspan = 1,
															level = 0
														},
														moduleType = "CLIMATE",
														buttonPressMode = "SHORT",
														buttonName = "LOWER_VENT"
									})
									:Times(0)
							end

							RUN_AFTER(HMIResponse, 10000)
					end)

					--RSDL must respond with "resultCode: USER_DISALLOWED, success: false, info: "The driver disallows this remote-control RPC" to this application.
					EXPECT_RESPONSE(cid, { success = false, resultCode = "USER_DISALLOWED", info = "The driver disallows this remote-control RPC" })
					:Timeout(11000)
				end
			--End Test case CommonRequestCheck.9.1.2

		-----------------------------------------------------------------------------------------
	--End Test case CommonRequestCheck.9.1


	--Begin Test case CommonRequestCheck.9.2
	--Description: 	For GetInteriorVehicleData

		--Requirement/Diagrams id in jira:
				--Requirement
				--Requirement

		--Verification criteria:
				--In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies

		-----------------------------------------------------------------------------------------
		-------------------------FOR FRONT PASSENGER ZONE----------------------------------------

			--Begin Precondition.1. HMI sends notification RC.OnDeviceLocationChanged(<deviceID>) to RSDL (zone:Front Passenger)
			--Description: HMI sends notification RC.OnDeviceLocationChanged(<deviceID>) to RSDL

				function Test:ChangedLocation_Front()
					--hmi side: HMI sends notification RC.OnDeviceLocationChanged(<deviceID>) to RSDL
					self.hmiConnection:SendNotification("RC.OnDeviceLocationChanged",
						{device = {name = "127.0.0.1", id = device1mac, isSDLAllowed = true},
							deviceLocation =
								{
									colspan = 2,
									row = 0,
									rowspan = 2,
									col = 1,
									levelspan = 1,
									level = 0
								}
						})
				end
			--End Precondition.1

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.9.2.1
			--Description: application sends GetInteriorVehicleData as Back Right and ModuleType = RADIO
				function Test:GetInterior_RightRADIO()
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
								col = 1,
								levelspan = 1,
								level = 0,
							}
						},
						subscribe = true
					})

					--hmi side: expect RSDL sends RC.GetInteriorVehicleDataConsent request to HMI
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

							local function HMIResponse()
									--hmi side: sending RC.GetInteriorVehicleDataConsent response to RSDL
									self.hmiConnection:SendResponse(data.id, "RC.GetInteriorVehicleDataConsent", "TIMED_OUT", {})

									--hmi side: expect RC.GetInteriorVehicleData request
									EXPECT_HMICALL("RC.GetInteriorVehicleData")
									:Times(0)
									:Do(function(_,data)
											--hmi side: sending RC.GetInteriorVehicleData response
											self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
													moduleData = {
														moduleType = "RADIO",
														moduleZone = {
															col = 1,
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

									end)
							end

							RUN_AFTER(HMIResponse, 10000)
					end)

					--RSDL must respond with "resultCode: USER_DISALLOWED, success: false, info: "The driver disallows this remote-control RPC" to this application.
					EXPECT_RESPONSE(cid, { success = false, resultCode = "USER_DISALLOWED", info = "The driver disallows this remote-control RPC" })
					:Timeout(11000)
				end
			--End Test case CommonRequestCheck.9.2.1

		-----------------------------------------------------------------------------------------
		-------------------------FOR LEFT PASSENGER ZONE----------------------------------------

			--Begin Precondition.1. HMI sends notification RC.OnDeviceLocationChanged(<deviceID>) to RSDL (zone:Left Passenger)
			--Description: HMI sends notification RC.OnDeviceLocationChanged(<deviceID>) to RSDL

				function Test:ChangedLocation_Left()
					--hmi side: HMI sends notification RC.OnDeviceLocationChanged(<deviceID>) to RSDL
					self.hmiConnection:SendNotification("RC.OnDeviceLocationChanged",
						{device = {name = "127.0.0.1", id = device1mac, isSDLAllowed = true},
							deviceLocation =
								{
									colspan = 2,
									row = 1,
									rowspan = 2,
									col = 0,
									levelspan = 1,
									level = 0
								}
						})
				end
			--End Precondition.1

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.9.2.2
			--Description: application sends GetInteriorVehicleData as Back Right and ModuleType = RADIO
				function Test:GetInterior_RightRADIO()
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
								col = 1,
								levelspan = 1,
								level = 0,
							}
						},
						subscribe = true
					})

					--hmi side: expect RSDL sends RC.GetInteriorVehicleDataConsent request to HMI
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
							local function HMIResponse()
									--hmi side: sending RC.GetInteriorVehicleDataConsent response to RSDL
									self.hmiConnection:SendResponse(data.id, "RC.GetInteriorVehicleDataConsent", "TIMED_OUT", {})

									--hmi side: expect RC.GetInteriorVehicleData request
									EXPECT_HMICALL("RC.GetInteriorVehicleData")
									:Times(0)
									:Do(function(_,data)
											--hmi side: sending RC.GetInteriorVehicleData response
											self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
													moduleData = {
														moduleType = "RADIO",
														moduleZone = {
															col = 1,
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

									end)
							end

							RUN_AFTER(HMIResponse, 10000)
					end)

					--RSDL must respond with "resultCode: USER_DISALLOWED, success: false, info: "The driver disallows this remote-control RPC" to this application.
					EXPECT_RESPONSE(cid, { success = false, resultCode = "USER_DISALLOWED", info = "The driver disallows this remote-control RPC" })
					:Timeout(11000)
				end
			--End Test case CommonRequestCheck.9.2.2

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.9.2.3
			--Description: application sends GetInteriorVehicleData as Not Existed zone and ModuleType = CLIMATE
				function Test:GetInterior_NotExistedCLIMATE()
					--mobile side: In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleData",
					{
						moduleDescription =
						{
							moduleType = "CLIMATE",
							moduleZone =
							{
								colspan = 2,
								row = 2,
								rowspan = 2,
								col = 2,
								levelspan = 1,
								level = 0,
							}
						},
						subscribe = true
					})

					--hmi side: expect RSDL sends RC.GetInteriorVehicleDataConsent request to HMI
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
							local function HMIResponse()
									--hmi side: sending RC.GetInteriorVehicleDataConsent response to RSDL
									self.hmiConnection:SendResponse(data.id, "RC.GetInteriorVehicleDataConsent", "TIMED_OUT", {})

									--hmi side: expect RC.GetInteriorVehicleData request
									EXPECT_HMICALL("RC.GetInteriorVehicleData")
									:Times(0)
									:Do(function(_,data)
											--hmi side: sending RC.GetInteriorVehicleData response
											self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
												moduleData =
												{
													moduleType = "CLIMATE",
													moduleZone =
													{
														colspan = 2,
														row = 2,
														rowspan = 2,
														col = 2,
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

									end)
							end

							RUN_AFTER(HMIResponse, 10000)
					end)

					--RSDL must respond with "resultCode: USER_DISALLOWED, success: false, info: "The driver disallows this remote-control RPC" to this application.
					EXPECT_RESPONSE(cid, { success = false, resultCode = "USER_DISALLOWED", info = "The driver disallows this remote-control RPC" })
					:Timeout(11000)
				end
			--End Test case CommonRequestCheck.9.2.3

		-----------------------------------------------------------------------------------------
	--End Test case CommonRequestCheck.9.2


	--Begin Test case CommonRequestCheck.9.3
	--Description: 	For GetInteriorVehicleData

		--Requirement/Diagrams id in jira:
				--Requirement
				--Requirement

		--Verification criteria:
				--In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies

		-----------------------------------------------------------------------------------------
		-------------------------FOR FRONT PASSENGER ZONE----------------------------------------

			--Begin Precondition.1. HMI sends notification RC.OnDeviceLocationChanged(<deviceID>) to RSDL (zone:Front Passenger)
			--Description: HMI sends notification RC.OnDeviceLocationChanged(<deviceID>) to RSDL

				function Test:ChangedLocation_Front()
					--hmi side: HMI sends notification RC.OnDeviceLocationChanged(<deviceID>) to RSDL
					self.hmiConnection:SendNotification("RC.OnDeviceLocationChanged",
						{device = {name = "127.0.0.1", id = device1mac, isSDLAllowed = true},
							deviceLocation =
								{
									colspan = 2,
									row = 0,
									rowspan = 2,
									col = 1,
									levelspan = 1,
									level = 0
								}
						})
				end
			--End Precondition.1

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.9.3.1
			--Description: application sends SetInteriorVehicleData as Back Left and ModuleType = RADIO
				function Test:SetInterior_BackLeftRADIO()
					--mobile side: In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies
					local cid = self.mobileSession:SendRPC("SetInteriorVehicleData",
					{
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

					--hmi side: expect RSDL sends RC.GetInteriorVehicleDataConsent request to HMI
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
							local function HMIResponse()
									--hmi side: sending RC.GetInteriorVehicleDataConsent response to RSDL
									self.hmiConnection:SendResponse(data.id, "RC.GetInteriorVehicleDataConsent", "TIMED_OUT", {})

									--hmi side: expect RC.SetInteriorVehicleData request
									EXPECT_HMICALL("RC.SetInteriorVehicleData")
									:Times(0)
									:Do(function(_,data)
											--hmi side: sending RC.SetInteriorVehicleData response
											self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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

										end)
							end

							RUN_AFTER(HMIResponse, 10000)
					end)

					--RSDL must respond with "resultCode: USER_DISALLOWED, success: false, info: "The driver disallows this remote-control RPC" to this application.
					EXPECT_RESPONSE(cid, { success = false, resultCode = "USER_DISALLOWED", info = "The driver disallows this remote-control RPC" })
					:Timeout(11000)
				end
			--End Test case CommonRequestCheck.9.3.1

		-----------------------------------------------------------------------------------------
		-------------------------FOR LEFT PASSENGER ZONE----------------------------------------

			--Begin Precondition.1. HMI sends notification RC.OnDeviceLocationChanged(<deviceID>) to RSDL (zone:Left Passenger)
			--Description: HMI sends notification RC.OnDeviceLocationChanged(<deviceID>) to RSDL

				function Test:ChangedLocation_Left()
					--hmi side: HMI sends notification RC.OnDeviceLocationChanged(<deviceID>) to RSDL
					self.hmiConnection:SendNotification("RC.OnDeviceLocationChanged",
						{device = {name = "127.0.0.1", id = device1mac, isSDLAllowed = true},
							deviceLocation =
								{
									colspan = 2,
									row = 1,
									rowspan = 2,
									col = 0,
									levelspan = 1,
									level = 0
								}
						})
				end
			--End Precondition.1

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.9.3.2
			--Description: application sends SetInteriorVehicleData as Driver zone and ModuleType = RADIO
				function Test:SetInterior_DriverRADIO()
					--mobile side: In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies
					local cid = self.mobileSession:SendRPC("SetInteriorVehicleData",
					{
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
								band = "FM"
							}
						}
					})

					--hmi side: expect RSDL sends RC.GetInteriorVehicleDataConsent request to HMI
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
							local function HMIResponse()
									--hmi side: sending RC.GetInteriorVehicleDataConsent response to RSDL
									self.hmiConnection:SendResponse(data.id, "RC.GetInteriorVehicleDataConsent", "TIMED_OUT", {})

									--hmi side: expect RC.SetInteriorVehicleData request
									EXPECT_HMICALL("RC.SetInteriorVehicleData")
									:Times(0)
									:Do(function(_,data)
											--hmi side: sending RC.SetInteriorVehicleData response
											self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
															band = "FM"
														}
													}
											})

										end)
							end

							RUN_AFTER(HMIResponse, 10000)
					end)

					--RSDL must respond with "resultCode: USER_DISALLOWED, success: false, info: "The driver disallows this remote-control RPC" to this application.
					EXPECT_RESPONSE(cid, { success = false, resultCode = "USER_DISALLOWED", info = "The driver disallows this remote-control RPC" })
					:Timeout(11000)
				end
			--End Test case CommonRequestCheck.9.3.2

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.9.3.3
			--Description: application sends SetInteriorVehicleData as Back Right and ModuleType = CLIMATE
				function Test:SetInterior_DriverAllowLeftCLIMATE()
					--mobile side: In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies
					local cid = self.mobileSession:SendRPC("SetInteriorVehicleData",
					{
						moduleData =
						{
							moduleType = "CLIMATE",
							moduleZone =
							{
								colspan = 2,
								row = 1,
								rowspan = 2,
								col = 1,
								levelspan = 1,
								level = 0
							},
							climateControlData =
							{
								fanSpeed = 50,
								desiredTemp = 24,
								temperatureUnit = "CELSIUS"
							}
						}
					})

					--hmi side: expect RSDL sends RC.GetInteriorVehicleDataConsent request to HMI
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
							local function HMIResponse()
									--hmi side: sending RC.GetInteriorVehicleDataConsent response to RSDL
									self.hmiConnection:SendResponse(data.id, "RC.GetInteriorVehicleDataConsent", "TIMED_OUT", {})

									--hmi side: expect RC.SetInteriorVehicleData request
									EXPECT_HMICALL("RC.SetInteriorVehicleData")
									:Times(0)
									:Do(function(_,data)
											--hmi side: sending RC.SetInteriorVehicleData response
											self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
												moduleData =
												{
													moduleType = "CLIMATE",
													moduleZone =
													{
														colspan = 2,
														row = 1,
														rowspan = 2,
														col = 1,
														levelspan = 1,
														level = 0
													},
													climateControlData =
													{
														fanSpeed = 50,
														desiredTemp = 24,
														temperatureUnit = "CELSIUS"
													}
												}
											})

										end)
							end

							RUN_AFTER(HMIResponse, 10000)
					end)

					--RSDL must respond with "resultCode: USER_DISALLOWED, success: false, info: "The driver disallows this remote-control RPC" to this application.
					EXPECT_RESPONSE(cid, { success = false, resultCode = "USER_DISALLOWED", info = "The driver disallows this remote-control RPC" })
					:Timeout(11000)
				end
			--End Test case CommonRequestCheck.9.3.3

		-----------------------------------------------------------------------------------------
	--End Test case CommonRequestCheck.9.3

--=================================================END TEST CASES 9==========================================================--


function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end