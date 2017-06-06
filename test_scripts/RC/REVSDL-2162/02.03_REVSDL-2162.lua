local commonSteps = require("user_modules/shared_testcases/commonSteps")
commonSteps:CheckSDLPath()
commonSteps:DeleteLogsFileAndPolicyTable()

local commonPreconditions = require("user_modules/shared_testcases/commonPreconditions")
commonPreconditions:BackupFile("sdl_preloaded_pt.json")
commonPreconditions:ReplaceFile("sdl_preloaded_pt.json", "./files/jsons/RC/rc_2164_sdl_preloaded_pt.json")

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
----------Requirement: GetInteriorVehicleDataCapabilies - rules for policies checks----------
---------------------------------------------------------------------------------------------
--=========================================================================================--



--===============PLEASE USE PT FILE: "sdl_preloaded_pt.json" UNDER: \TestData\Requirement\ FOR THIS SCRIPT=====================--


--=================================================BEGIN TEST CASES 3==========================================================--
	--Begin Test suit CommonRequestCheck.3 for Req.#3

	--Description: 3. In case 	a. remote-control passenger's app sends GetInteriorVehicleDataCapabilities request
									-- > with or without defined zone
									-- > with more than one OR without moduleType in the array
									-- and
								-- b. RSDL has or has not received app's device location from the vehicle (via OnDeviceLocationChanged)
									-- RSDL must
									-- respond with (DISALLOWED, success:false, "Information: one moduleType must be provided")

	--Begin Test case CommonRequestCheck.3.1
	--Description: 	check "equipment" permissions against the zone from app's request with OR without defined "zone" and more than one OR without "moduleType"

		--Requirement/Diagrams id in jira:
				--Requirement

		--Verification criteria:
				-- check "equipment" permissions against the zone from app's request.

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.1.1
			--Description: application sends GetInteriorVehicleDataCapabilities as Driver and ModuleType = RADIO
				function Test:DriverRADIO_DISALLOWED()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
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
						moduleTypes = {"RADIO", "CLIMATE"}
					})


					--RSDL must respond with (DISALLOWED, success:false, "Information: one moduleType must be provided")
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Information: one moduleType must be provided" })
				end
			--End Test case CommonRequestCheck.3.1.1

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.1.2
			--Description: application sends GetInteriorVehicleDataCapabilities as Front Passenger and ModuleType = RADIO
				function Test:FrontRADIO_DISALLOWED()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
					{
						zone =
						{
							colspan = 2,
							row = 0,
							rowspan = 2,
							col = 1,
							levelspan = 1,
							level = 0
						},
						moduleTypes = {"RADIO", "RADIO", "CLIMATE"}
					})

					--RSDL must respond with (DISALLOWED, success:false, "Information: one moduleType must be provided")
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Information: one moduleType must be provided" })

				end
			--End Test case CommonRequestCheck.3.1.2

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.1.3
			--Description: application sends GetInteriorVehicleDataCapabilities as Left Passenger and ModuleType = RADIO
				function Test:LeftRADIO_DISALLOWED()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
					{
						zone =
						{
							colspan = 2,
							row = 1,
							rowspan = 2,
							col = 0,
							levelspan = 1,
							level = 0
						},
						moduleTypes = {"CLIMATE", "CLIMATE", "RADIO"}
					})

					--RSDL must respond with (DISALLOWED, success:false, "Information: one moduleType must be provided")
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Information: one moduleType must be provided" })

				end
			--End Test case CommonRequestCheck.3.1.3

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.1.4
			--Description: application sends GetInteriorVehicleDataCapabilities as Driver and ModuleType = RADIO
				function Test:Driver_DISALLOWED()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
					{
						zone =
						{
							colspan = 2,
							row = 0,
							rowspan = 2,
							col = 0,
							levelspan = 1,
							level = 0
						}
					})


					--RSDL must respond with (DISALLOWED, success:false, "Information: one moduleType must be provided")
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Information: one moduleType must be provided" })
				end
			--End Test case CommonRequestCheck.3.1.4

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.1.5
			--Description: application sends GetInteriorVehicleDataCapabilities as Front Passenger and ModuleType = RADIO
				function Test:Front_DISALLOWED()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
					{
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

					--RSDL must respond with (DISALLOWED, success:false, "Information: one moduleType must be provided")
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Information: one moduleType must be provided" })

				end
			--End Test case CommonRequestCheck.3.1.5

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.1.6
			--Description: application sends GetInteriorVehicleDataCapabilities as Left Passenger and ModuleType = RADIO
				function Test:Left_DISALLOWED()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
					{
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

					--RSDL must respond with (DISALLOWED, success:false, "Information: one moduleType must be provided")
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Information: one moduleType must be provided" })

				end
			--End Test case CommonRequestCheck.3.1.6

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.2.7
			--Description: application sends GetInteriorVehicleDataCapabilities as Driver and ModuleType = RADIO
				function Test:RADIO_CLIMATE_DISALLOWED()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
					{
						moduleTypes = {"RADIO", "CLIMATE"}
					})


					--RSDL must respond with (DISALLOWED, success:false, "Information: one moduleType must be provided")
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Information: one moduleType must be provided" })
				end
			--End Test case CommonRequestCheck.3.2.7

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.2.8
			--Description: application sends GetInteriorVehicleDataCapabilities as Front Passenger and ModuleType = RADIO
				function Test:RADIO_CLIMATE_DISALLOWED()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
					{
						moduleTypes = {"RADIO", "RADIO", "CLIMATE"}
					})

					--RSDL must respond with (DISALLOWED, success:false, "Information: one moduleType must be provided")
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Information: one moduleType must be provided" })

				end
			--End Test case CommonRequestCheck.3.2.8

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.2.9
			--Description: application sends GetInteriorVehicleDataCapabilities as Left Passenger and ModuleType = RADIO
				function Test:RADIO_CLIMATE_DISALLOWED()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
					{
						moduleTypes = {"CLIMATE", "CLIMATE", "RADIO"}
					})

					--RSDL must respond with (DISALLOWED, success:false, "Information: one moduleType must be provided")
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Information: one moduleType must be provided" })

				end
			--End Test case CommonRequestCheck.3.2.9

		-----------------------------------------------------------------------------------------
		-------------------------FOR BACK LEFT PASSENGER ZONE----------------------------------------

			--Begin Precondition.1. HMI sends notification RC.OnDeviceLocationChanged(<deviceID>) to RSDL (zone:BACK LEFT Passenger)
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

			--Begin Test case CommonRequestCheck.3.2.10
			--Description: application sends GetInteriorVehicleDataCapabilities as Driver and ModuleType = RADIO
				function Test:WithoutModuleTypeAndZone_DISALLOWED()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
					{
					})


					--RSDL must respond with (DISALLOWED, success:false, "Information: one moduleType must be provided")
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Information: one moduleType must be provided" })
				end
			--End Test case CommonRequestCheck.3.2.10

		-----------------------------------------------------------------------------------------
	--End Test case CommonRequestCheck.3.1




	--Begin Test case CommonRequestCheck.3.2
	--Description: 	check "equipment" permissions against the zone from app's request with OR without defined "zone" and more than one OR without "moduleType"
					-- and RSDL receives OnDeviceLocationChanged notification

		--Requirement/Diagrams id in jira:
				--Requirement

		--Verification criteria:
				-- check "equipment" permissions against the zone from app's request.

		-----------------------------------------------------------------------------------------
		------------------------------FOR DRIVER ZONE-----------------------------------------

			--Begin Precondition.1. HMI sends notification RC.OnDeviceLocationChanged(<deviceID>) to RSDL (zone:Driver)
			--Description: HMI sends notification RC.OnDeviceLocationChanged(<deviceID>) to RSDL

				function Test:ChangedLocation_Driver()
					--hmi side: HMI sends notification RC.OnDeviceLocationChanged(<deviceID>) to RSDL
					self.hmiConnection:SendNotification("RC.OnDeviceLocationChanged",
						{device = {name = "127.0.0.1", id = device1mac, isSDLAllowed = true},
							deviceLocation =
								{
									colspan = 2,
									row = 0,
									rowspan = 2,
									col = 0,
									levelspan = 1,
									level = 0
								}
						})
				end
			--End Precondition.1

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.1.1
			--Description: application sends GetInteriorVehicleDataCapabilities as Driver and ModuleType = RADIO
				function Test:DriverRADIO_DISALLOWED()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
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
						moduleTypes = {"RADIO", "CLIMATE"}
					})


					--RSDL must respond with (DISALLOWED, success:false, "Information: one moduleType must be provided")
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Information: one moduleType must be provided" })
				end
			--End Test case CommonRequestCheck.3.1.1

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.1.2
			--Description: application sends GetInteriorVehicleDataCapabilities as Front Passenger and ModuleType = RADIO
				function Test:FrontRADIO_DISALLOWED()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
					{
						zone =
						{
							colspan = 2,
							row = 0,
							rowspan = 2,
							col = 1,
							levelspan = 1,
							level = 0
						},
						moduleTypes = {"RADIO", "RADIO", "CLIMATE"}
					})

					--RSDL must respond with (DISALLOWED, success:false, "Information: one moduleType must be provided")
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Information: one moduleType must be provided" })

				end
			--End Test case CommonRequestCheck.3.1.2

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.1.3
			--Description: application sends GetInteriorVehicleDataCapabilities as Left Passenger and ModuleType = RADIO
				function Test:LeftRADIO_DISALLOWED()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
					{
						zone =
						{
							colspan = 2,
							row = 1,
							rowspan = 2,
							col = 0,
							levelspan = 1,
							level = 0
						},
						moduleTypes = {"CLIMATE", "CLIMATE", "RADIO"}
					})

					--RSDL must respond with (DISALLOWED, success:false, "Information: one moduleType must be provided")
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Information: one moduleType must be provided" })

				end
			--End Test case CommonRequestCheck.3.1.3

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.1.4
			--Description: application sends GetInteriorVehicleDataCapabilities as Driver and ModuleType = RADIO
				function Test:Driver_DISALLOWED()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
					{
						zone =
						{
							colspan = 2,
							row = 0,
							rowspan = 2,
							col = 0,
							levelspan = 1,
							level = 0
						}
					})


					--RSDL must respond with (DISALLOWED, success:false, "Information: one moduleType must be provided")
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Information: one moduleType must be provided" })
				end
			--End Test case CommonRequestCheck.3.1.4

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.1.5
			--Description: application sends GetInteriorVehicleDataCapabilities as Front Passenger and ModuleType = RADIO
				function Test:Front_DISALLOWED()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
					{
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

					--RSDL must respond with (DISALLOWED, success:false, "Information: one moduleType must be provided")
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Information: one moduleType must be provided" })

				end
			--End Test case CommonRequestCheck.3.1.5

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.1.6
			--Description: application sends GetInteriorVehicleDataCapabilities as Left Passenger and ModuleType = RADIO
				function Test:Left_DISALLOWED()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
					{
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

					--RSDL must respond with (DISALLOWED, success:false, "Information: one moduleType must be provided")
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Information: one moduleType must be provided" })

				end
			--End Test case CommonRequestCheck.3.1.6

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.2.7
			--Description: application sends GetInteriorVehicleDataCapabilities as Driver and ModuleType = RADIO
				function Test:RADIO_CLIMATE_DISALLOWED()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
					{
						moduleTypes = {"RADIO", "CLIMATE"}
					})


					--RSDL must respond with (DISALLOWED, success:false, "Information: one moduleType must be provided")
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Information: one moduleType must be provided" })
				end
			--End Test case CommonRequestCheck.3.2.7

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.2.8
			--Description: application sends GetInteriorVehicleDataCapabilities as Front Passenger and ModuleType = RADIO
				function Test:RADIO_CLIMATE_DISALLOWED()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
					{
						moduleTypes = {"RADIO", "RADIO", "CLIMATE"}
					})

					--RSDL must respond with (DISALLOWED, success:false, "Information: one moduleType must be provided")
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Information: one moduleType must be provided" })

				end
			--End Test case CommonRequestCheck.3.2.8

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.2.9
			--Description: application sends GetInteriorVehicleDataCapabilities as Left Passenger and ModuleType = RADIO
				function Test:RADIO_CLIMATE_DISALLOWED()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
					{
						moduleTypes = {"CLIMATE", "CLIMATE", "RADIO"}
					})

					--RSDL must respond with (DISALLOWED, success:false, "Information: one moduleType must be provided")
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Information: one moduleType must be provided" })

				end
			--End Test case CommonRequestCheck.3.2.9

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.2.10
			--Description: application sends GetInteriorVehicleDataCapabilities as Driver and ModuleType = RADIO
				function Test:WithoutModuleTypeAndZone_DISALLOWED()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
					{
					})


					--RSDL must respond with (DISALLOWED, success:false, "Information: one moduleType must be provided")
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Information: one moduleType must be provided" })
				end
			--End Test case CommonRequestCheck.3.2.10

		-----------------------------------------------------------------------------------------
		-------------------------FOR BACK LEFT PASSENGER ZONE------------------------------------

			--Begin Precondition.1. HMI sends notification RC.OnDeviceLocationChanged(<deviceID>) to RSDL (zone:BACK LEFT Passenger)
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

			--Begin Test case CommonRequestCheck.3.1.1
			--Description: application sends GetInteriorVehicleDataCapabilities as Driver and ModuleType = RADIO
				function Test:DriverRADIO_DISALLOWED()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
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
						moduleTypes = {"RADIO", "CLIMATE"}
					})


					--RSDL must respond with (DISALLOWED, success:false, "Information: one moduleType must be provided")
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Information: one moduleType must be provided" })
				end
			--End Test case CommonRequestCheck.3.1.1

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.1.2
			--Description: application sends GetInteriorVehicleDataCapabilities as Front Passenger and ModuleType = RADIO
				function Test:FrontRADIO_DISALLOWED()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
					{
						zone =
						{
							colspan = 2,
							row = 0,
							rowspan = 2,
							col = 1,
							levelspan = 1,
							level = 0
						},
						moduleTypes = {"RADIO", "RADIO", "CLIMATE"}
					})

					--RSDL must respond with (DISALLOWED, success:false, "Information: one moduleType must be provided")
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Information: one moduleType must be provided" })

				end
			--End Test case CommonRequestCheck.3.1.2

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.1.3
			--Description: application sends GetInteriorVehicleDataCapabilities as Left Passenger and ModuleType = RADIO
				function Test:LeftRADIO_DISALLOWED()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
					{
						zone =
						{
							colspan = 2,
							row = 1,
							rowspan = 2,
							col = 0,
							levelspan = 1,
							level = 0
						},
						moduleTypes = {"CLIMATE", "CLIMATE", "RADIO"}
					})

					--RSDL must respond with (DISALLOWED, success:false, "Information: one moduleType must be provided")
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Information: one moduleType must be provided" })

				end
			--End Test case CommonRequestCheck.3.1.3

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.1.4
			--Description: application sends GetInteriorVehicleDataCapabilities as Driver and ModuleType = RADIO
				function Test:Driver_DISALLOWED()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
					{
						zone =
						{
							colspan = 2,
							row = 0,
							rowspan = 2,
							col = 0,
							levelspan = 1,
							level = 0
						}
					})


					--RSDL must respond with (DISALLOWED, success:false, "Information: one moduleType must be provided")
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Information: one moduleType must be provided" })
				end
			--End Test case CommonRequestCheck.3.1.4

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.1.5
			--Description: application sends GetInteriorVehicleDataCapabilities as Front Passenger and ModuleType = RADIO
				function Test:Front_DISALLOWED()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
					{
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

					--RSDL must respond with (DISALLOWED, success:false, "Information: one moduleType must be provided")
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Information: one moduleType must be provided" })

				end
			--End Test case CommonRequestCheck.3.1.5

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.1.6
			--Description: application sends GetInteriorVehicleDataCapabilities as Left Passenger and ModuleType = RADIO
				function Test:Left_DISALLOWED()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
					{
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

					--RSDL must respond with (DISALLOWED, success:false, "Information: one moduleType must be provided")
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Information: one moduleType must be provided" })

				end
			--End Test case CommonRequestCheck.3.1.6

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.2.7
			--Description: application sends GetInteriorVehicleDataCapabilities as Driver and ModuleType = RADIO
				function Test:RADIO_CLIMATE_DISALLOWED()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
					{
						moduleTypes = {"RADIO", "CLIMATE"}
					})


					--RSDL must respond with (DISALLOWED, success:false, "Information: one moduleType must be provided")
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Information: one moduleType must be provided" })
				end
			--End Test case CommonRequestCheck.3.2.7

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.2.8
			--Description: application sends GetInteriorVehicleDataCapabilities as Front Passenger and ModuleType = RADIO
				function Test:RADIO_CLIMATE_DISALLOWED()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
					{
						moduleTypes = {"RADIO", "RADIO", "CLIMATE"}
					})

					--RSDL must respond with (DISALLOWED, success:false, "Information: one moduleType must be provided")
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Information: one moduleType must be provided" })

				end
			--End Test case CommonRequestCheck.3.2.8

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.2.9
			--Description: application sends GetInteriorVehicleDataCapabilities as Left Passenger and ModuleType = RADIO
				function Test:RADIO_CLIMATE_DISALLOWED()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
					{
						moduleTypes = {"CLIMATE", "CLIMATE", "RADIO"}
					})

					--RSDL must respond with (DISALLOWED, success:false, "Information: one moduleType must be provided")
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Information: one moduleType must be provided" })

				end
			--End Test case CommonRequestCheck.3.2.9

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.2.10
			--Description: application sends GetInteriorVehicleDataCapabilities as Driver and ModuleType = RADIO
				function Test:WithoutModuleTypeAndZone_DISALLOWED()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
					{
					})


					--RSDL must respond with (DISALLOWED, success:false, "Information: one moduleType must be provided")
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Information: one moduleType must be provided" })
				end
			--End Test case CommonRequestCheck.3.2.10

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

			--Begin Test case CommonRequestCheck.3.1.1
			--Description: application sends GetInteriorVehicleDataCapabilities as Driver and ModuleType = RADIO
				function Test:DriverRADIO_DISALLOWED()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
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
						moduleTypes = {"RADIO", "CLIMATE"}
					})


					--RSDL must respond with (DISALLOWED, success:false, "Information: one moduleType must be provided")
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Information: one moduleType must be provided" })
				end
			--End Test case CommonRequestCheck.3.1.1

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.1.2
			--Description: application sends GetInteriorVehicleDataCapabilities as Front Passenger and ModuleType = RADIO
				function Test:FrontRADIO_DISALLOWED()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
					{
						zone =
						{
							colspan = 2,
							row = 0,
							rowspan = 2,
							col = 1,
							levelspan = 1,
							level = 0
						},
						moduleTypes = {"RADIO", "RADIO", "CLIMATE"}
					})

					--RSDL must respond with (DISALLOWED, success:false, "Information: one moduleType must be provided")
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Information: one moduleType must be provided" })

				end
			--End Test case CommonRequestCheck.3.1.2

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.1.3
			--Description: application sends GetInteriorVehicleDataCapabilities as Left Passenger and ModuleType = RADIO
				function Test:LeftRADIO_DISALLOWED()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
					{
						zone =
						{
							colspan = 2,
							row = 1,
							rowspan = 2,
							col = 0,
							levelspan = 1,
							level = 0
						},
						moduleTypes = {"CLIMATE", "CLIMATE", "RADIO"}
					})

					--RSDL must respond with (DISALLOWED, success:false, "Information: one moduleType must be provided")
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Information: one moduleType must be provided" })

				end
			--End Test case CommonRequestCheck.3.1.3

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.1.4
			--Description: application sends GetInteriorVehicleDataCapabilities as Driver and ModuleType = RADIO
				function Test:Driver_DISALLOWED()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
					{
						zone =
						{
							colspan = 2,
							row = 0,
							rowspan = 2,
							col = 0,
							levelspan = 1,
							level = 0
						}
					})


					--RSDL must respond with (DISALLOWED, success:false, "Information: one moduleType must be provided")
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Information: one moduleType must be provided" })
				end
			--End Test case CommonRequestCheck.3.1.4

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.1.5
			--Description: application sends GetInteriorVehicleDataCapabilities as Front Passenger and ModuleType = RADIO
				function Test:Front_DISALLOWED()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
					{
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

					--RSDL must respond with (DISALLOWED, success:false, "Information: one moduleType must be provided")
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Information: one moduleType must be provided" })

				end
			--End Test case CommonRequestCheck.3.1.5

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.1.6
			--Description: application sends GetInteriorVehicleDataCapabilities as Left Passenger and ModuleType = RADIO
				function Test:Left_DISALLOWED()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
					{
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

					--RSDL must respond with (DISALLOWED, success:false, "Information: one moduleType must be provided")
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Information: one moduleType must be provided" })

				end
			--End Test case CommonRequestCheck.3.1.6

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.2.7
			--Description: application sends GetInteriorVehicleDataCapabilities as Driver and ModuleType = RADIO
				function Test:RADIO_CLIMATE_DISALLOWED()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
					{
						moduleTypes = {"RADIO", "CLIMATE"}
					})


					--RSDL must respond with (DISALLOWED, success:false, "Information: one moduleType must be provided")
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Information: one moduleType must be provided" })
				end
			--End Test case CommonRequestCheck.3.2.7

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.2.8
			--Description: application sends GetInteriorVehicleDataCapabilities as Front Passenger and ModuleType = RADIO
				function Test:RADIO_CLIMATE_DISALLOWED()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
					{
						moduleTypes = {"RADIO", "RADIO", "CLIMATE"}
					})

					--RSDL must respond with (DISALLOWED, success:false, "Information: one moduleType must be provided")
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Information: one moduleType must be provided" })

				end
			--End Test case CommonRequestCheck.3.2.8

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.2.9
			--Description: application sends GetInteriorVehicleDataCapabilities as Left Passenger and ModuleType = RADIO
				function Test:RADIO_CLIMATE_DISALLOWED()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
					{
						moduleTypes = {"CLIMATE", "CLIMATE", "RADIO"}
					})

					--RSDL must respond with (DISALLOWED, success:false, "Information: one moduleType must be provided")
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Information: one moduleType must be provided" })

				end
			--End Test case CommonRequestCheck.3.2.9

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.2.10
			--Description: application sends GetInteriorVehicleDataCapabilities as Driver and ModuleType = RADIO
				function Test:WithoutModuleTypeAndZone_DISALLOWED()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
					{
					})


					--RSDL must respond with (DISALLOWED, success:false, "Information: one moduleType must be provided")
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Information: one moduleType must be provided" })
				end
			--End Test case CommonRequestCheck.3.2.10

		-----------------------------------------------------------------------------------------
		-------------------------FOR BACK RIGHT PASSENGER ZONE----------------------------------------

			--Begin Precondition.1. HMI sends notification RC.OnDeviceLocationChanged(<deviceID>) to RSDL (zone:BACK Right Passenger)
			--Description: HMI sends notification RC.OnDeviceLocationChanged(<deviceID>) to RSDL

				function Test:ChangedLocation_Right()
					--hmi side: HMI sends notification RC.OnDeviceLocationChanged(<deviceID>) to RSDL
					self.hmiConnection:SendNotification("RC.OnDeviceLocationChanged",
						{device = {name = "127.0.0.1", id = device1mac, isSDLAllowed = true},
							deviceLocation =
								{
									colspan = 2,
									row = 1,
									rowspan = 2,
									col = 1,
									levelspan = 1,
									level = 0
								}
						})
				end
			--End Precondition.1

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.1.1
			--Description: application sends GetInteriorVehicleDataCapabilities as Driver and ModuleType = RADIO
				function Test:DriverRADIO_DISALLOWED()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
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
						moduleTypes = {"RADIO", "CLIMATE"}
					})


					--RSDL must respond with (DISALLOWED, success:false, "Information: one moduleType must be provided")
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Information: one moduleType must be provided" })
				end
			--End Test case CommonRequestCheck.3.1.1

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.1.2
			--Description: application sends GetInteriorVehicleDataCapabilities as Front Passenger and ModuleType = RADIO
				function Test:FrontRADIO_DISALLOWED()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
					{
						zone =
						{
							colspan = 2,
							row = 0,
							rowspan = 2,
							col = 1,
							levelspan = 1,
							level = 0
						},
						moduleTypes = {"RADIO", "RADIO", "CLIMATE"}
					})

					--RSDL must respond with (DISALLOWED, success:false, "Information: one moduleType must be provided")
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Information: one moduleType must be provided" })

				end
			--End Test case CommonRequestCheck.3.1.2

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.1.3
			--Description: application sends GetInteriorVehicleDataCapabilities as Left Passenger and ModuleType = RADIO
				function Test:LeftRADIO_DISALLOWED()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
					{
						zone =
						{
							colspan = 2,
							row = 1,
							rowspan = 2,
							col = 0,
							levelspan = 1,
							level = 0
						},
						moduleTypes = {"CLIMATE", "CLIMATE", "RADIO"}
					})

					--RSDL must respond with (DISALLOWED, success:false, "Information: one moduleType must be provided")
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Information: one moduleType must be provided" })

				end
			--End Test case CommonRequestCheck.3.1.3

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.1.4
			--Description: application sends GetInteriorVehicleDataCapabilities as Driver and ModuleType = RADIO
				function Test:Driver_DISALLOWED()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
					{
						zone =
						{
							colspan = 2,
							row = 0,
							rowspan = 2,
							col = 0,
							levelspan = 1,
							level = 0
						}
					})


					--RSDL must respond with (DISALLOWED, success:false, "Information: one moduleType must be provided")
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Information: one moduleType must be provided" })
				end
			--End Test case CommonRequestCheck.3.1.4

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.1.5
			--Description: application sends GetInteriorVehicleDataCapabilities as Front Passenger and ModuleType = RADIO
				function Test:Front_DISALLOWED()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
					{
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

					--RSDL must respond with (DISALLOWED, success:false, "Information: one moduleType must be provided")
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Information: one moduleType must be provided" })

				end
			--End Test case CommonRequestCheck.3.1.5

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.1.6
			--Description: application sends GetInteriorVehicleDataCapabilities as Left Passenger and ModuleType = RADIO
				function Test:Left_DISALLOWED()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
					{
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

					--RSDL must respond with (DISALLOWED, success:false, "Information: one moduleType must be provided")
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Information: one moduleType must be provided" })

				end
			--End Test case CommonRequestCheck.3.1.6

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.2.7
			--Description: application sends GetInteriorVehicleDataCapabilities as Driver and ModuleType = RADIO
				function Test:RADIO_CLIMATE_DISALLOWED()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
					{
						moduleTypes = {"RADIO", "CLIMATE"}
					})


					--RSDL must respond with (DISALLOWED, success:false, "Information: one moduleType must be provided")
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Information: one moduleType must be provided" })
				end
			--End Test case CommonRequestCheck.3.2.7

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.2.8
			--Description: application sends GetInteriorVehicleDataCapabilities as Front Passenger and ModuleType = RADIO
				function Test:RADIO_CLIMATE_DISALLOWED()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
					{
						moduleTypes = {"RADIO", "RADIO", "CLIMATE"}
					})

					--RSDL must respond with (DISALLOWED, success:false, "Information: one moduleType must be provided")
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Information: one moduleType must be provided" })

				end
			--End Test case CommonRequestCheck.3.2.8

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.2.9
			--Description: application sends GetInteriorVehicleDataCapabilities as Left Passenger and ModuleType = RADIO
				function Test:RADIO_CLIMATE_DISALLOWED()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
					{
						moduleTypes = {"CLIMATE", "CLIMATE", "RADIO"}
					})

					--RSDL must respond with (DISALLOWED, success:false, "Information: one moduleType must be provided")
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Information: one moduleType must be provided" })

				end
			--End Test case CommonRequestCheck.3.2.9

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.2.10
			--Description: application sends GetInteriorVehicleDataCapabilities as Driver and ModuleType = RADIO
				function Test:WithoutModuleTypeAndZone_DISALLOWED()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
					{
					})


					--RSDL must respond with (DISALLOWED, success:false, "Information: one moduleType must be provided")
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Information: one moduleType must be provided" })
				end
			--End Test case CommonRequestCheck.3.2.10

		-----------------------------------------------------------------------------------------
		-------------------------FOR THE ZONE IS NOT EXISTED-------------------------------------

			--Begin Precondition.1. HMI sends notification RC.OnDeviceLocationChanged(<deviceID>) to RSDL (zone:BACK Right Passenger)
			--Description: HMI sends notification RC.OnDeviceLocationChanged(<deviceID>) to RSDL

				function Test:ChangedLocation_Right()
					--hmi side: HMI sends notification RC.OnDeviceLocationChanged(<deviceID>) to RSDL
					self.hmiConnection:SendNotification("RC.OnDeviceLocationChanged",
						{device = {name = "127.0.0.1", id = device1mac, isSDLAllowed = true},
							deviceLocation =
								{
									colspan = 2,
									row = 100,
									rowspan = 2,
									col = 100,
									levelspan = 1,
									level = 0
								}
						})
				end
			--End Precondition.1

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.1.1
			--Description: application sends GetInteriorVehicleDataCapabilities as Driver and ModuleType = RADIO
				function Test:DriverRADIO_DISALLOWED()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
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
						moduleTypes = {"RADIO", "CLIMATE"}
					})


					--RSDL must respond with (DISALLOWED, success:false, "Information: one moduleType must be provided")
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Information: one moduleType must be provided" })
				end
			--End Test case CommonRequestCheck.3.1.1

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.1.2
			--Description: application sends GetInteriorVehicleDataCapabilities as Front Passenger and ModuleType = RADIO
				function Test:FrontRADIO_DISALLOWED()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
					{
						zone =
						{
							colspan = 2,
							row = 0,
							rowspan = 2,
							col = 1,
							levelspan = 1,
							level = 0
						},
						moduleTypes = {"RADIO", "RADIO", "CLIMATE"}
					})

					--RSDL must respond with (DISALLOWED, success:false, "Information: one moduleType must be provided")
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Information: one moduleType must be provided" })

				end
			--End Test case CommonRequestCheck.3.1.2

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.1.3
			--Description: application sends GetInteriorVehicleDataCapabilities as Left Passenger and ModuleType = RADIO
				function Test:LeftRADIO_DISALLOWED()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
					{
						zone =
						{
							colspan = 2,
							row = 1,
							rowspan = 2,
							col = 0,
							levelspan = 1,
							level = 0
						},
						moduleTypes = {"CLIMATE", "CLIMATE", "RADIO"}
					})

					--RSDL must respond with (DISALLOWED, success:false, "Information: one moduleType must be provided")
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Information: one moduleType must be provided" })

				end
			--End Test case CommonRequestCheck.3.1.3

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.1.4
			--Description: application sends GetInteriorVehicleDataCapabilities as Driver and ModuleType = RADIO
				function Test:Driver_DISALLOWED()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
					{
						zone =
						{
							colspan = 2,
							row = 0,
							rowspan = 2,
							col = 0,
							levelspan = 1,
							level = 0
						}
					})


					--RSDL must respond with (DISALLOWED, success:false, "Information: one moduleType must be provided")
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Information: one moduleType must be provided" })
				end
			--End Test case CommonRequestCheck.3.1.4

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.1.5
			--Description: application sends GetInteriorVehicleDataCapabilities as Front Passenger and ModuleType = RADIO
				function Test:Front_DISALLOWED()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
					{
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

					--RSDL must respond with (DISALLOWED, success:false, "Information: one moduleType must be provided")
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Information: one moduleType must be provided" })

				end
			--End Test case CommonRequestCheck.3.1.5

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.1.6
			--Description: application sends GetInteriorVehicleDataCapabilities as Left Passenger and ModuleType = RADIO
				function Test:Left_DISALLOWED()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
					{
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

					--RSDL must respond with (DISALLOWED, success:false, "Information: one moduleType must be provided")
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Information: one moduleType must be provided" })

				end
			--End Test case CommonRequestCheck.3.1.6

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.2.7
			--Description: application sends GetInteriorVehicleDataCapabilities as Driver and ModuleType = RADIO
				function Test:RADIO_CLIMATE_DISALLOWED()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
					{
						moduleTypes = {"RADIO", "CLIMATE"}
					})


					--RSDL must respond with (DISALLOWED, success:false, "Information: one moduleType must be provided")
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Information: one moduleType must be provided" })
				end
			--End Test case CommonRequestCheck.3.2.7

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.2.8
			--Description: application sends GetInteriorVehicleDataCapabilities as Front Passenger and ModuleType = RADIO
				function Test:RADIO_CLIMATE_DISALLOWED()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
					{
						moduleTypes = {"RADIO", "RADIO", "CLIMATE"}
					})

					--RSDL must respond with (DISALLOWED, success:false, "Information: one moduleType must be provided")
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Information: one moduleType must be provided" })

				end
			--End Test case CommonRequestCheck.3.2.8

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.2.9
			--Description: application sends GetInteriorVehicleDataCapabilities as Left Passenger and ModuleType = RADIO
				function Test:RADIO_CLIMATE_DISALLOWED()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
					{
						moduleTypes = {"CLIMATE", "CLIMATE", "RADIO"}
					})

					--RSDL must respond with (DISALLOWED, success:false, "Information: one moduleType must be provided")
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Information: one moduleType must be provided" })

				end
			--End Test case CommonRequestCheck.3.2.9

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.2.10
			--Description: application sends GetInteriorVehicleDataCapabilities as Driver and ModuleType = RADIO
				function Test:WithoutModuleTypeAndZone_DISALLOWED()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
					{
					})


					--RSDL must respond with (DISALLOWED, success:false, "Information: one moduleType must be provided")
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Information: one moduleType must be provided" })
				end
			--End Test case CommonRequestCheck.3.2.10

		-----------------------------------------------------------------------------------------

	--End Test case CommonRequestCheck.3.2


--=================================================END TEST CASES 3==========================================================--

function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end