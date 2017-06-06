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



--===============PLEASE USE PT FILE: "sdl_preloaded_pt.json" UNDER: \TestData\Requirement\ FOR THIS SCRIPT=====================--

--=================================================BEGIN TEST CASES 5==========================================================--
	--Begin Test suit CommonRequestCheck.5 for Req.#5

	--Description: 3. In case 	a. remote-control passenger's app sends GetInteriorVehicleDataCapabilities request
									-- > without defined zone
									-- > with one moduleType in the array
									-- and
								-- b. RSDL has not received app's device location from the vehicle (via OnDeviceLocationChanged)
									-- RSDL must respond with (DISALLOWED, success:false, "Information: zone must be provided")

	--Begin Test case CommonRequestCheck.5.1
	--Description: 	RSDL must respond with (DISALLOWED, success:false, "Information: zone must be provided")

		--Requirement/Diagrams id in jira:
				--Requirement

		--Verification criteria:
				-- RSDL must respond with (DISALLOWED, success:false, "Information: zone must be provided")

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.5.1.1
			--Description: application sends GetInteriorVehicleDataCapabilities as Driver and ModuleType = RADIO
				function Test:PassengerRADIO_DISALLOWED()
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
					{
						moduleTypes = {"RADIO"}
					})


					--RSDL must respond with (DISALLOWED, success:false, "Information: zone must be provided")
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Information: zone must be provided" })
				end
			--End Test case CommonRequestCheck.5.1.1

		-----------------------------------------------------------------------------------------
	--End Test case CommonRequestCheck.5.1


--=================================================END TEST CASES 5==========================================================--

function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end