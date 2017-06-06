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

--======================================Requirement========================================--
---------------------------------------------------------------------------------------------
----------Requirement: GetInteriorVehicleDataCapabilies - rules for policies checks----------
---------------------------------------------------------------------------------------------
--=========================================================================================--

--=================================================BEGIN TEST CASES 1==========================================================--
	--Begin Test suit CommonRequestCheck.1 for Req.#1

	--Description: 1. In case 	a. remote-control passenger's app sends GetInteriorVehicleDataCapabilities request
									-- > with defined zone
									-- > with one moduleType in the array
									-- and
								-- b. RSDL has not received app's device location from the vehicle (via OnDeviceLocationChanged)
									-- RSDL must
									-- check "equipment" permissions against the zone from app's request.
									-- Information:
									-- per requirements from Requirement:
									-- -> if GetInteriorVehicleDataCapabilities is in "auto_allow", RSDL will transfer it to the vehicle
									-- -> if GetInteriorVehicleDataCapabilities is in "driver_allow", RSDL will trigger a permission prompt (if accepted - then transfer app's request to the vehicle; if denied - then return "user_disallowed" to the app)


	--Begin Test case CommonRequestCheck.1.2
	--Description: 	check "equipment" permissions against the zone from app's request in driver_allow (denied)

		--Requirement/Diagrams id in jira:
				--Requirement

		--Verification criteria:
				-- check "equipment" permissions against the zone from app's request. in driver_allow (denied)

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.1.2.1
			--Description: application sends GetInteriorVehicleDataCapabilities as Front Passenger and ModuleType = RADIO
				function Test:DriverAllow_FrontRADIO_Denied()
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
			--End Test case CommonRequestCheck.1.2.1

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.1.2.2
			--Description: application sends GetInteriorVehicleDataCapabilities as Left Passenger and ModuleType = RADIO
				function Test:DriverAllow_LeftRADIO_Denied()
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
						self.hmiConnection:SendResponse(data.id, "RC.GetInteriorVehicleDataConsent", "SUCCESS", {allowed = false})
					end)


					--mobile side: expect USER_DISALLOWED response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "USER_DISALLOWED" })

				end
			--End Test case CommonRequestCheck.1.2.2

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.1.2.3
			--Description: application sends GetInteriorVehicleDataCapabilities as Left Passenger and ModuleType = CLIMATE
				function Test:DriverAllow_LeftCLIMATE_Denied()
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
						moduleTypes = {"CLIMATE"}
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
						self.hmiConnection:SendResponse(data.id, "RC.GetInteriorVehicleDataConsent", "SUCCESS", {allowed = false})
					end)


					--mobile side: expect USER_DISALLOWED response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "USER_DISALLOWED" })

				end
			--End Test case CommonRequestCheck.1.2.3

		-----------------------------------------------------------------------------------------

	--End Test case CommonRequestCheck.1.2

--=================================================END TEST CASES 1==========================================================--

function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end
