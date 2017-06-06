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

--=================================================BEGIN TEST CASES 2==========================================================--
	--Begin Test suit CommonRequestCheck.2 for Req.#2

	--Description: 2. In case an RC application from <deviceID> device sends a valid rc-RPC with <app-provided interiorZone>, <moduleType> and <params> allowed by app's assigned policies
							-- and RSDL has received RC.OnDeviceLocationChanged(<deviceID>, <HMI-provided interiorZone>) from HMI
							-- and "equipment" section of policies database contains this RPC name with <params> in <moduleType> in "auto_allow" sub-section of <HMI-provided interiorZone> section
							-- RSDL must send this RPC with these <params> to the vehicle (HMI).


	--Begin Test case CommonRequestCheck.2.1
	--Description: 	For ButtonPress

		--Requirement/Diagrams id in jira:
				--Requirement


		--Verification criteria:
				--RSDL must send this RPC with these <params> to the vehicle (HMI).

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

		-- -----------------------------------------------------------------------------------------


			--Begin Test case CommonRequestCheck.2.2.4
			--Description: application sends GetInteriorVehicleData as Not Existed and ModuleType = RADIO
				function Test:GetInterior_NotExistedRADIO()
					--mobile sends request for precondition
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleData",
					{
						moduleDescription =
						{
							moduleType = "RADIO",
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

					--hmi side: expect RC.GetInteriorVehicleData request
					EXPECT_HMICALL("RC.GetInteriorVehicleData")
					:Do(function(_,data)
							--hmi side: sending RC.GetInteriorVehicleData response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
									moduleData = {
										moduleType = "RADIO",
										moduleZone = {
											col = 2,
											colspan = 2,
											level = 0,
											levelspan = 1,
											row = 2,
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

						--mobile side: expect SUCCESS response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
				end
			--End Test case CommonRequestCheck.2.2.4


function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end