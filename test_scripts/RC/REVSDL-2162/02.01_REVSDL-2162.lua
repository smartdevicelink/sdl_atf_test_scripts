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


--=================================================BEGIN TEST CASES 2.1==========================================================--
	--Begin Test suit CommonRequestCheck.2 for Req.#2 (WITH DEFINED ZONE)

	--Description: 2. In case 	a. remote-control passenger's app sends GetInteriorVehicleDataCapabilities request
									-- > with or without defined zone
									-- > with one moduleType in the array
									-- and
								-- b. RSDL has received app's device location from the vehicle (via OnDeviceLocationChanged)
									-- RSDL must
									-- check "equipment" permissions against the zone from OnDeviceLocationChanged.
									-- Information:
									-- per requirements from Requirement:
									-- -> if GetInteriorVehicleDataCapabilities is in "auto_allow", RSDL will transfer it to the vehicle
									-- -> if GetInteriorVehicleDataCapabilities is in "driver_allow", RSDL will trigger a permission prompt (if accepted - then transfer app's request to the vehicle; if denied - then return "user_disallowed" to the app)

	--Begin Test case CommonRequestCheck.2.1
	--Description: 	RSDL has received app's device location from the vehicle (via OnDeviceLocationChanged)  in auto_allow

		--Requirement/Diagrams id in jira:
				--Requirement

		--Verification criteria:
				-- RSDL has received app's device location from the vehicle (via OnDeviceLocationChanged) in auto_allow

		-----------------------------------------------------------------------------------------
		------------------------------FOR DRIVER ZONE--------------------------------------------

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

			--Begin Test case CommonRequestCheck.2.1.1
			--Description: application sends GetInteriorVehicleDataCapabilities as Driver and ModuleType = RADIO (app's requested zone is not exited)
				function Test:AutoAllow_DriverRADIO()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
					{
						zone =
						{
							colspan = 2,
							row = 2,
							rowspan = 2,
							col = 2,
							levelspan = 1,
							level = 0
						},
						moduleTypes = {"RADIO"}
					})

					--hmi side: expect RC.GetInteriorVehicleDataCapabilities request
					EXPECT_HMICALL("RC.GetInteriorVehicleDataCapabilities")
					:Do(function(_,data)
						--hmi side: sending RC.GetInteriorVehicleDataCapabilities response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
														interiorVehicleDataCapabilities = {
															{
																moduleZone = {
																	colspan = 2,
																	row = 2,
																	rowspan = 2,
																	col = 2,
																	levelspan = 1,
																	level = 0
																},
																moduleType = "RADIO"
															}
														}
						})
					end)

					--mobile side: expect SUCCESS response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", interiorVehicleDataCapabilities = {
																								{
																									moduleZone = {
																										col = 2,
																										row = 2,
																										level = 0,
																										colspan = 2,
																										rowspan = 2,
																										levelspan = 1
																									},
																									moduleType = "RADIO"
																								}
																							}
					})
				end
			--End Test case CommonRequestCheck.2.1.1

		-----------------------------------------------------------------------------------------
	--End Test case CommonRequestCheck.2.1


	--Begin Test case CommonRequestCheck.2.2
	--Description: 	RSDL has received app's device location from the vehicle (via OnDeviceLocationChanged)  (denied)

		--Requirement/Diagrams id in jira:
				--Requirement

		--Verification criteria:
				-- check "equipment" permissions against the zone from app's request. in driver_allow (denied)

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

			--Begin Test case CommonRequestCheck.2.2.1
			--Description: application sends GetInteriorVehicleDataCapabilities as Front Passenger and ModuleType = RADIO
				function Test:DriverAllow_FrontRADIO_Denied()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
					{
						zone =
						{
							colspan = 2,
							row = 100,
							rowspan = 2,
							col = 100,
							levelspan = 1,
							level = 0
						},
						moduleTypes = {"RADIO"}
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
						self.hmiConnection:SendResponse(data.id, "RC.GetInteriorVehicleDataConsent", "SUCCESS", {allowed = false})
					end)


					--mobile side: expect USER_DISALLOWED response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "USER_DISALLOWED" })

				end
			--End Test case CommonRequestCheck.2.2.1

		-----------------------------------------------------------------------------------------
	--End Test case CommonRequestCheck.2.2



	--Begin Test case CommonRequestCheck.2.3
	--Description: 	RSDL has received app's device location from the vehicle (via OnDeviceLocationChanged)  (allowed)

		--Requirement/Diagrams id in jira:
				--Requirement

		--Verification criteria:
				-- check "equipment" permissions against the zone from app's request. in driver_allow (allowed)

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

			--Begin Test case CommonRequestCheck.2.3.1
			--Description: application sends GetInteriorVehicleDataCapabilities as Left Passenger and ModuleType = RADIO
				function Test:DriverAllow_LeftRADIO_Allow()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
					{
						zone =
						{
							colspan = 2,
							row = 100,
							rowspan = 2,
							col = 100,
							levelspan = 1,
							level = 0
						},
						moduleTypes = {"RADIO"}
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

						--hmi side: expect RC.GetInteriorVehicleDataCapabilities request
						EXPECT_HMICALL("RC.GetInteriorVehicleDataCapabilities")
						:Do(function(_,data)
							--hmi side: sending RC.GetInteriorVehicleDataCapabilities response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
															interiorVehicleDataCapabilities = {
																{
																	moduleZone = {
																		colspan = 2,
																		row = 100,
																		rowspan = 2,
																		col = 100,
																		levelspan = 1,
																		level = 0
																	},
																	moduleType = "RADIO"
																}
															}
							})
						end)
					end)


					--mobile side: expect SUCCESS response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", interiorVehicleDataCapabilities = {
																								{
																									moduleZone = {
																										col = 100,
																										row = 100,
																										level = 0,
																										colspan = 2,
																										rowspan = 2,
																										levelspan = 1
																									},
																									moduleType = "RADIO"
																								}
																							}
					})

				end
			--End Test case CommonRequestCheck.2.3.1

		-----------------------------------------------------------------------------------------
	--End Test case CommonRequestCheck.2.3


--=================================================END TEST CASES 2.1==========================================================--

function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end