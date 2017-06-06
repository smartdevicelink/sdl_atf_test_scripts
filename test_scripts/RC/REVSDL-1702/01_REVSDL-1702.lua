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
--groups_PrimaryRC Group
local arrayGroups_PrimaryRC = revsdl.arrayGroups_PrimaryRC()

local device1mac = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--======================================Requirement========================================--
---------------------------------------------------------------------------------------------
--------------Requirement: SetInteriorVehicleData: conditions to return----------------------
----------------------------------READ_ONLY resultCode---------------------------------------
---------------------------------------------------------------------------------------------
--=========================================================================================--




--=================================================BEGIN TEST CASES 1==========================================================--
	--Begin Test suit CommonRequestCheck.1 for Req.#1

	--Description: In case: application sends valid SetInteriorVehicleData with just read-only parameters in "radioControlData" struct, for muduleType: RADIO, RSDL must
						--respond with "resultCode: READ_ONLY, success:false" to this application and do not process this RPC.


	--Begin Test case CommonRequestCheck.1.1
	--Description: 	--PASSENGER's Device
					--RSDL responds with "resultCode: READ_ONLY, success:false" to this application and do not process this RPC.

		--Requirement/Diagrams id in jira:
				--Requirement
				--https://adc.luxoft.com/jira/secure/attachment/127928/127928_model_SetInteriorVehicleData-READ_ONLY.png

		--Verification criteria:
				--For PASSENGER'S Device

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.1.1.1
			--Description: Sending SetInteriorVehicleData request with just read-only parameters
				function Test:PASSENGER_READONLY()

					--mobile side: sending SetInteriorVehicleData request with just read-only parameters in "radioControlData" struct, for muduleType: RADIO
					local cid = self.mobileSession:SendRPC("SetInteriorVehicleData",
					{
						moduleData =
						{
							radioControlData =
							{
								radioEnable = true,
								state = "ACQUIRED",
								availableHDs = 1,
								signalStrength = 50,
								rdsData =
								{
									PS = "12345678",
									RT = "",
									CT = "123456789012345678901234",
									PI = "",
									PTY = 0,
									TP = true,
									TA = false,
									REG = ""
								},
								signalChangeThreshold = 10
							},
							moduleType = "RADIO",
							moduleZone =
							{
								colspan = 2,
								row = 0,
								rowspan = 2,
								col = 0,
								levelspan = 1,
								level = 0
							}
						}
					})

				--mobile side: respond with "resultCode: READ_ONLY, success:false"
				EXPECT_RESPONSE(cid, { success = false, resultCode = "READ_ONLY"})

				end
			--End Test case CommonRequestCheck.1.1.1

		-----------------------------------------------------------------------------------------

	--End Test case CommonRequestCheck.1.1


	--Begin Test case CommonRequestCheck.1.2
	--Description: 	--DRIVER's Device
					--RSDL responds with "resultCode: READ_ONLY, success:false" to this application and do not process this RPC.

		--Requirement/Diagrams id in jira:
				--Requirement
				--https://adc.luxoft.com/jira/secure/attachment/127928/127928_model_SetInteriorVehicleData-READ_ONLY.png

		--Verification criteria:
				--For DRIVER'S Device

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.1.2.1
			--Description: Sending SetInteriorVehicleData request with just read-only parameters
				function Test:SetPASSENGERToDRIVER()

					--hmi side: send request RC.OnDeviceRankChanged
					self.hmiConnection:SendNotification("RC.OnDeviceRankChanged",
															{deviceRank = "DRIVER", device = {name = "127.0.0.1", id = device1mac, isSDLAllowed = true}})

					--mobile side: Expect OnPermissionsChange notification for Driver's device
					self.mobileSession:ExpectNotification("OnPermissionsChange", arrayGroups_PrimaryRC )

					--mobile side: OnHMIStatus notifications with deviceRank = "DRIVER"
					self.mobileSession:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "DRIVER" })

				end
			--End Test case CommonRequestCheck.1.2.1

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.1.2.2
			--Description: Sending SetInteriorVehicleData request with just read-only parameters
				function Test:DRIVER_READONLY()

					--mobile side: sending SetInteriorVehicleData request with just read-only parameters in "radioControlData" struct, for muduleType: RADIO
					local cid = self.mobileSession:SendRPC("SetInteriorVehicleData",
					{
						moduleData =
						{
							radioControlData =
							{
								radioEnable = true,
								state = "ACQUIRED",
								availableHDs = 1,
								signalStrength = 50,
								rdsData =
								{
									PS = "12345678",
									RT = "",
									CT = "123456789012345678901234",
									PI = "",
									PTY = 0,
									TP = true,
									TA = false,
									REG = ""
								},
								signalChangeThreshold = 10
							},
							moduleType = "RADIO",
							moduleZone =
							{
								colspan = 2,
								row = 0,
								rowspan = 2,
								col = 0,
								levelspan = 1,
								level = 0
							}
						}
					})

				--mobile side: respond with "resultCode: READ_ONLY, success:false"
				EXPECT_RESPONSE(cid, { success = false, resultCode = "READ_ONLY"})

				end
			--End Test case CommonRequestCheck.1.2.2

		-----------------------------------------------------------------------------------------

	--End Test case CommonRequestCheck.1.2

--=================================================END TEST CASES 1==========================================================--

function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end